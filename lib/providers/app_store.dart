import 'dart:async';

import 'package:acai_stock/data/firebase_auth_service.dart';
import 'package:acai_stock/data/export_service.dart';
import 'package:acai_stock/data/local_database.dart';
import 'package:acai_stock/data/notification_service.dart';
import 'package:acai_stock/models/product.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthScreen { login, register, recovery, resetPassword }

class AppStore extends ChangeNotifier {
  AppStore() {
    unawaited(_initialize());
  }

  static const _notificationsKey = 'notifications';

  bool get usesRemoteAuth => true;
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
  final ExportService _exportService = ExportService();
  final NotificationService _notificationService = NotificationService.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  SharedPreferences? _prefs;
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
    await _notificationService.initialize();
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
      _products = [..._products, created];
    } else {
      await _database.updateProduct(normalizedProduct);
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

  // Placeholder for cloud backup. Previously used Supabase.
  // If you want Firebase Storage backups, implement upload logic here.
  Future<String> backupDatabaseToCloud() async {
    return 'Backup em nuvem não configurado. Configure Firebase Storage.';
  }

  void setAuthScreen(AuthScreen screen) {
    authScreen = screen;
    notifyListeners();
  }

  Future<String?> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (password.isEmpty) return 'Preencha o campo de senha.';

    try {
      await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      final user = _authService.currentUser;
      if (user == null) {
        return 'Falha ao autenticar. Verifique seus dados e tente novamente.';
      }
      currentUserName = user.email?.split('@').first;
      isLoggedIn = true;
      await _loadProducts();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Erro ao fazer login.';
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';

    try {
      await _authService.signUp(
        email: email.trim(),
        password: password,
      );
      final user = _authService.currentUser;
      if (user == null) {
        return 'Falha ao criar conta.';
      }
      currentUserName = user.email?.split('@').first;
      isLoggedIn = true;
      await _loadProducts();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Erro ao criar conta.';
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> recoverPassword({
    required String email,
  }) async {
    if (email.isEmpty) return 'Informe seu e-mail.';

    try {
      await _authService.sendPasswordResetEmail(email.trim());
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Erro ao enviar e-mail de recuperação.';
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateRecoveredPassword({
    required String password,
    required String confirmPassword,
  }) async {
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    if (password != confirmPassword) return 'As senhas não conferem.';

    try {
      await _authService.updatePassword(password);
      await logout();
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Erro ao atualizar senha.';
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Erro ao fazer logout no Firebase
    }
    isLoggedIn = false;
    isPasswordRecoveryMode = false;
    currentUserName = null;
    authScreen = AuthScreen.login;
    notifyListeners();
  }

  Future<void> _initializeAuthSession() async {
    final user = _authService.currentUser;
    if (user != null) {
      isLoggedIn = true;
      currentUserName = user.email?.split('@').first;
    }
    notifyListeners();
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
    super.dispose();
  }
}
