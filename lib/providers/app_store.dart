import 'dart:async';

import 'package:acai_stock/data/backup_service.dart';
import 'package:acai_stock/data/export_service.dart';
import 'package:acai_stock/data/local_credentials_store.dart';
import 'package:acai_stock/data/local_database.dart';
import 'package:acai_stock/data/notification_service.dart';
import 'package:acai_stock/data/sync_queue.dart';
import 'package:acai_stock/data/sync_service.dart';
import 'package:acai_stock/models/product.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthScreen { login, register, recovery, resetPassword }

class AppStore extends ChangeNotifier {
  AppStore({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient {
    unawaited(_initialize());
  }

  static const _notificationsKey = 'notifications';

  final SupabaseClient? _supabaseClient;

  bool get usesRemoteAuth => _supabaseClient != null;
  static const _darkModeKey = 'dark_mode';
  static const _languageKey = 'language';

  final List<Product> _seedProducts = [
    Product(
      nome: 'Polpa de Açaí',
      categoria: 'Açaí Base',
      quantidade: 6,
      pontoPedido: 10,
      lote: 'AC-203',
      dataValidade: DateTime.now().add(const Duration(days: 14)),
      trend: -3,
      galpaoZerado: false,
    ),
    Product(
      nome: 'Copo Plástico 300ml',
      categoria: 'Embalagens',
      quantidade: 9,
      pontoPedido: 12,
      lote: 'CP-517',
      dataValidade: DateTime.now().add(const Duration(days: 180)),
      trend: -2,
      galpaoZerado: false,
    ),
    Product(
      nome: 'Granola',
      categoria: 'Toppings',
      quantidade: 4,
      pontoPedido: 8,
      lote: 'GR-338',
      dataValidade: DateTime.now().add(const Duration(days: 20)),
      trend: -1,
      galpaoZerado: false,
    ),
    Product(
      nome: 'Leite em Pó',
      categoria: 'Complementos',
      quantidade: 0,
      pontoPedido: 6,
      lote: 'LP-101',
      dataValidade: DateTime.now().add(const Duration(days: 90)),
      trend: -4,
      galpaoZerado: true,
    ),
    Product(
      nome: 'Calda de Morango',
      categoria: 'Toppings',
      quantidade: 0,
      pontoPedido: 5,
      lote: 'CM-882',
      dataValidade: DateTime.now().add(const Duration(days: 3)),
      trend: -6,
      galpaoZerado: true,
    ),
    Product(
      nome: 'Morango Congelado',
      categoria: 'Toppings',
      quantidade: 18,
      pontoPedido: 10,
      lote: 'MC-044',
      dataValidade: DateTime.now().add(const Duration(days: 3)),
      trend: 2,
      galpaoZerado: false,
    ),
  ];

  final LocalDatabase _database = LocalDatabase.instance;
  final BackupService _backupService = BackupService();
  final ExportService _exportService = ExportService();
  final NotificationService _notificationService = NotificationService.instance;
  final LocalCredentialsStore _credentials = LocalCredentialsStore();
  SharedPreferences? _prefs;
  StreamSubscription? _authStateSubscription;
  List<Product> _products = [];

  AuthScreen authScreen = AuthScreen.login;
  bool isInitializing = true;
  bool isLoggedIn = false;
  bool isPasswordRecoveryMode = false;
  bool notifications = true;
  bool darkMode = false;
  String language = 'Português';
  String? currentUserName;
  int lossQuantityLast30Days = 0;

  List<Product> get products => List.unmodifiable(_products);

  int get totalProducts =>
      _products.fold(0, (sum, item) => sum + item.quantidade);
  int get weeklyGrowth => 12;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.lowStock).toList();
  List<Product> get outProducts =>
      _products.where((p) => p.outOfStock).toList();
  List<Product> get criticalAlerts =>
      _products.where((p) => p.galpaoZerado || p.outOfStock).toList();
  List<Product> get expiryAlerts =>
      _products.where((p) => p.nearExpiry).toList();

  Future<void> _loadProducts() async {
    final dbProducts = await _database.getProducts();
    if (dbProducts.isEmpty) {
      await _database.insertProducts(_seedProducts);
      _products = await _database.getProducts();
    } else {
      _products = dbProducts;
    }
    lossQuantityLast30Days = await _database.getLossQuantityLast30Days();
  }

  Future<void> _queueProductUpdate(Product product) async {
    if (_supabaseClient == null) return;
    await _database.addSyncOnUpdate(product);
    unawaited(SyncService.instance.syncWithServer());
  }

  Future<void> _queueProductDelete(int id) async {
    if (_supabaseClient == null) return;
    await _database.addSyncOnDelete(id);
    unawaited(SyncService.instance.syncWithServer());
  }

  Future<String?> _validateUniqueBarcode(Product product) async {
    final barcode = product.barcode?.trim();
    if (barcode == null || barcode.isEmpty) return null;

    Product? existing = productByBarcode(barcode);
    existing ??= await _database.getProductByBarcode(barcode);
    if (existing != null && existing.id != product.id) {
      return 'Ja existe um produto cadastrado com este barcode.';
    }
    return null;
  }

  Future<void> _initialize() async {
    isInitializing = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    await _credentials.reload();
    await _notificationService.initialize();
    await SyncQueue.instance.initialize();
    SyncService.instance.initialize(_supabaseClient);
    await _initializeAuthSession();
    notifications = _prefs?.getBool(_notificationsKey) ?? true;
    darkMode = _prefs?.getBool(_darkModeKey) ?? false;
    language = _prefs?.getString(_languageKey) ?? 'Português';

    await _loadProducts();
    await _notifyCriticalProducts();

    isInitializing = false;
    notifyListeners();
  }

  List<Product> filterProducts({
    required String search,
    required String category,
    required String stockStatus,
  }) {
    final normalizedSearch = search.trim().toLowerCase();
    return _products.where((product) {
      final bySearch = normalizedSearch.isEmpty ||
          product.nome.toLowerCase().contains(normalizedSearch) ||
          product.lote.toLowerCase().contains(normalizedSearch);

      final byCategory =
          category == 'All Stock' || product.categoria == category;

      final byStatus = switch (stockStatus) {
        'In Stock' => !product.lowStock && !product.outOfStock,
        'Low' => product.lowStock,
        'Out of Stock' => product.outOfStock,
        _ => true,
      };

      return bySearch && byCategory && byStatus;
    }).toList();
  }

  List<String> get productCategories {
    final categories =
        _products.map((product) => product.categoria).toSet().toList()..sort();
    return ['All Stock', ...categories];
  }

  Future<void> restockProduct({
    required Product product,
    required int addedQuantity,
  }) async {
    if (product.id == null || addedQuantity <= 0) return;
    final updated = product.copyWith(
      quantidade: product.quantidade + addedQuantity,
      galpaoZerado: false,
    );
    await _database.updateProduct(updated);
    await _queueProductUpdate(updated);
    _products = _products.map((p) => p.id == updated.id ? updated : p).toList();
    await _notifyIfCritical(updated);
    notifyListeners();
  }

  Future<String?> saveProduct(Product product) async {
    if (product.nome.trim().isEmpty) return 'Informe o nome do produto.';
    if (product.categoria.trim().isEmpty) {
      return 'Informe a categoria do produto.';
    }
    if (product.lote.trim().isEmpty) return 'Informe o lote do produto.';
    if (product.quantidade < 0) return 'Quantidade inválida.';
    if (product.pontoPedido < 0) return 'Ponto de pedido inválido.';

    final barcode = product.barcode?.trim();
    final normalizedProduct = product.copyWith(
      barcode: barcode == null || barcode.isEmpty ? null : barcode,
    );
    final barcodeError = await _validateUniqueBarcode(normalizedProduct);
    if (barcodeError != null) return barcodeError;

    if (normalizedProduct.id == null) {
      final id = await _database.insertProduct(normalizedProduct);
      final created = normalizedProduct.copyWith(id: id);
      if (_supabaseClient != null) {
        await _database.addSyncOnCreate(created);
        unawaited(SyncService.instance.syncWithServer());
      }
      _products = [..._products, created];
    } else {
      await _database.updateProduct(normalizedProduct);
      await _queueProductUpdate(normalizedProduct);
      _products = _products
          .map((p) => p.id == normalizedProduct.id ? normalizedProduct : p)
          .toList();
    }
    notifyListeners();
    return null;
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id == null) return;
    await _database.deleteProductById(product.id!);
    await _queueProductDelete(product.id!);
    _products = _products.where((p) => p.id != product.id).toList();
    notifyListeners();
  }

  Product? productByBarcode(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    for (final p in _products) {
      if (p.barcode == code) return p;
    }
    return null;
  }

  Future<String?> confirmEntryByBarcode({
    required String barcode,
    required int quantity,
  }) async {
    final code = barcode.trim();
    if (code.isEmpty) return 'Informe um código.';
    if (quantity <= 0) return 'Quantidade inválida.';

    Product? product = productByBarcode(code);
    if (product == null) {
      product = await _database.getProductByBarcode(code);
      if (product != null) {
        _products = [..._products, product]
          ..sort((a, b) => a.nome.compareTo(b.nome));
      }
    }
    if (product == null) return 'Produto não encontrado para este código.';
    if (product.id == null) return 'Produto inválido.';

    final updated = product.copyWith(
      quantidade: product.quantidade + quantity,
      galpaoZerado: false,
    );
    await _database.updateProduct(updated);
    await _queueProductUpdate(updated);
    _products = _products.map((p) => p.id == updated.id ? updated : p).toList();
    await _notifyIfCritical(updated);
    notifyListeners();
    return null;
  }

  Future<void> discardLot(Product product) async {
    if (product.id == null) return;
    await _database.insertLossLog(
      productId: product.id,
      nome: product.nome,
      lote: product.lote,
      quantidade: product.quantidade,
      motivo: 'Vencimento',
    );
    await _database.deleteProductById(product.id!);
    await _queueProductDelete(product.id!);
    _products = _products.where((p) => p.id != product.id).toList();
    lossQuantityLast30Days = await _database.getLossQuantityLast30Days();
    notifyListeners();
  }

  Future<void> _notifyCriticalProducts() async {
    if (!notifications) return;
    for (final product in _products) {
      await _notifyIfCritical(product);
    }
  }

  Future<void> _notifyIfCritical(Product product) async {
    if (!notifications) return;
    if (product.id == null) return;
    if (product.quantidade <= product.pontoPedido) {
      await _notificationService.notifyLowStock(
        id: product.id!,
        productName: product.nome,
        quantity: product.quantidade,
        reorderPoint: product.pontoPedido,
      );
    }
  }

  Future<List<String>> exportReports() async {
    final lossLogs = await _database.getLossLogs();
    final inventory = await _database.getInventoryRaw();

    final csvPath = await _exportService.exportCsv(
      fileName: 'acai_stock_reports.csv',
      headers: const [
        'dataset',
        'id',
        'nome',
        'categoria/lote',
        'quantidade',
        'extra',
        'data'
      ],
      rows: [
        ...lossLogs.map(
          (e) => [
            'loss_logs',
            e['id'],
            e['nome'],
            e['lote'],
            e['quantidade'],
            e['motivo'],
            e['created_at'],
          ],
        ),
        ...inventory.map(
          (e) => [
            'inventory',
            e['id'],
            e['nome'],
            e['categoria'],
            e['quantidade'],
            'ponto_pedido=${e['ponto_pedido']}',
            e['last_updated'],
          ],
        ),
      ],
    );

    final pdfPath = await _exportService.exportPdf(
      fileName: 'acai_stock_inventory.pdf',
      title: 'Inventario Atual',
      headers: const [
        'Nome',
        'Categoria',
        'Qtd',
        'Ponto Pedido',
        'Lote',
        'Ultima atualizacao'
      ],
      rows: inventory
          .map(
            (e) => [
              e['nome'],
              e['categoria'],
              e['quantidade'],
              e['ponto_pedido'],
              e['lote'],
              e['last_updated'],
            ],
          )
          .toList(),
    );

    return [csvPath, pdfPath];
  }

  Future<String> backupDatabaseToCloud() {
    return _backupService.backupSQLiteToSupabase(_supabaseClient);
  }

  void setAuthScreen(AuthScreen screen) {
    authScreen = screen;
    notifyListeners();
  }

  Future<String?> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return 'Aguarde a inicialização e tente de novo.';
    final emailErr = _credentials.validateEmailFormat(email);
    if (emailErr != null) return emailErr;
    if (password.isEmpty) return 'Preencha o campo de senha.';

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        final user = response.user;
        if (user == null || response.session == null) {
          return 'Falha ao autenticar. Verifique seus dados e tente novamente.';
        }
        currentUserName = user.email?.split('@').first;
        isLoggedIn = true;
        await _loadProducts();
        notifyListeners();
        return null;
      } on AuthException catch (error) {
        return error.message;
      } catch (error) {
        return error.toString();
      }
    }

    final err = _credentials.validateLogin(email, password);
    if (err != null) return err;
    final account = _credentials.accountForEmail(email);
    if (account == null) return 'Conta não encontrada.';
    currentUserName = account.name;
    isLoggedIn = true;
    await _loadProducts();
    notifyListeners();
    return null;
  }

  Future<String?> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final emailErr = _credentials.validateEmailFormat(email);
    if (emailErr != null) return emailErr;
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient.auth.signUp(
          email: email.trim(),
          password: password,
        );
        if (response.session != null && response.user != null) {
          currentUserName = response.user!.email?.split('@').first;
          isLoggedIn = true;
          await _loadProducts();
          notifyListeners();
          return null;
        }
        return 'Conta criada. Verifique o e-mail para ativar sua conta.';
      } on AuthException catch (error) {
        return error.message;
      } catch (error) {
        return error.toString();
      }
    }

    final err = await _credentials.register(
      name: name,
      email: email,
      password: password,
    );
    if (err != null) return err;
    return loginWithCredentials(email: email, password: password);
  }

  Future<String?> recoverPassword({
    required String email,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return 'Aguarde a inicialização e tente de novo.';
    final emailErr = _credentials.validateEmailFormat(email);
    if (emailErr != null) return emailErr;

    if (_supabaseClient != null) {
      try {
        await _supabaseClient.auth.resetPasswordForEmail(
          email.trim(),
          redirectTo: 'acai-stock://auth-callback',
        );
        return null;
      } on AuthException catch (error) {
        return error.message;
      } catch (error) {
        return error.toString();
      }
    }

    final account = _credentials.accountForEmail(email);
    if (account == null) return 'Conta não encontrada.';
    return 'Recuperação local de senha não está disponível no momento. Configure Supabase ou use o login local.';
  }

  Future<String?> updateRecoveredPassword({
    required String password,
    required String confirmPassword,
  }) async {
    if (_supabaseClient == null) {
      return 'Recuperação pelo Supabase não está configurada.';
    }
    if (!isPasswordRecoveryMode) {
      return 'Abra o link de recuperação enviado por e-mail antes de redefinir a senha.';
    }
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    if (password != confirmPassword) return 'As senhas não conferem.';

    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: password),
      );
      await _supabaseClient.auth.signOut();
      isPasswordRecoveryMode = false;
      isLoggedIn = false;
      currentUserName = null;
      authScreen = AuthScreen.login;
      notifyListeners();
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> logout() async {
    if (_supabaseClient != null) {
      try {
        await _supabaseClient.auth.signOut();
      } catch (_) {
        // Erro ao fazer logout no Supabase
      }
    }
    isLoggedIn = false;
    isPasswordRecoveryMode = false;
    currentUserName = null;
    authScreen = AuthScreen.login;
    notifyListeners();
  }

  Future<void> _initializeAuthSession() async {
    if (_supabaseClient == null) return;

    final session = _supabaseClient.auth.currentSession;
    final user = session?.user;
    if (user != null) {
      isLoggedIn = true;
      currentUserName = user.email?.split('@').first;
    }

    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen(
      (authState) {
        final session = authState.session;
        final user = session?.user;
        if (authState.event == AuthChangeEvent.passwordRecovery) {
          isPasswordRecoveryMode = true;
          isLoggedIn = false;
          currentUserName = user?.email?.split('@').first;
          authScreen = AuthScreen.resetPassword;
        } else if (user != null) {
          isPasswordRecoveryMode = false;
          isLoggedIn = true;
          currentUserName = user.email?.split('@').first;
        } else {
          isPasswordRecoveryMode = false;
          isLoggedIn = false;
          currentUserName = null;
        }
        notifyListeners();
      },
    );
  }

  Future<void> toggleNotifications(bool value) async {
    notifications = value;
    await _prefs?.setBool(_notificationsKey, value);
    if (value) {
      await _notifyCriticalProducts();
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    darkMode = value;
    notifyListeners();
    await _prefs?.setBool(_darkModeKey, value);
  }

  void setLanguage(String value) {
    language = value;
    _prefs?.setString(_languageKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    SyncService.instance.dispose();
    super.dispose();
  }
}
