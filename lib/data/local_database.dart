import 'package:acai_stock/data/sync_queue.dart';
import 'package:acai_stock/models/product.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'acai_stock.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            categoria TEXT NOT NULL,
            quantidade INTEGER NOT NULL,
            ponto_pedido INTEGER NOT NULL,
            barcode TEXT UNIQUE,
            lote TEXT NOT NULL,
            data_validade TEXT NOT NULL,
            trend INTEGER NOT NULL,
            galpao_zerado INTEGER NOT NULL,
            last_updated TEXT NOT NULL
          )
        ''');
        await db
            .execute('CREATE INDEX idx_products_barcode ON products(barcode)');
        await db.execute(
            'CREATE INDEX idx_products_categoria ON products(categoria)');
        await db.execute('''
          CREATE TABLE loss_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            nome TEXT NOT NULL,
            lote TEXT NOT NULL,
            quantidade INTEGER NOT NULL,
            motivo TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN last_updated TEXT');
          await db.rawUpdate(
            "UPDATE products SET last_updated = ? WHERE last_updated IS NULL",
            [DateTime.now().toIso8601String()],
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
                'CREATE UNIQUE INDEX idx_products_barcode ON products(barcode)');
          } catch (_) {
            // Índice já pode existir
          }
          try {
            await db.execute(
                'CREATE INDEX idx_products_categoria ON products(categoria)');
          } catch (_) {
            // Índice já pode existir
          }
        }
      },
    );
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final code = barcode.trim();
    if (code.isEmpty) return null;
    final rows = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap()..remove('id'));
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'nome ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert('products', product.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    final data = product.copyWith(lastUpdated: DateTime.now()).toMap()
      ..remove('id');
    await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProductById(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertLossLog({
    required int? productId,
    required String nome,
    required String lote,
    required int quantidade,
    required String motivo,
  }) async {
    final db = await database;
    await db.insert('loss_logs', {
      'product_id': productId,
      'nome': nome,
      'lote': lote,
      'quantidade': quantidade,
      'motivo': motivo,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getLossQuantityLast30Days() async {
    final db = await database;
    final since =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantidade), 0) AS total FROM loss_logs WHERE created_at >= ?',
      [since],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, Object?>>> getLossLogs() async {
    final db = await database;
    return db.query('loss_logs', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, Object?>>> getInventoryRaw() async {
    final db = await database;
    return db.query('products', orderBy: 'nome ASC');
  }

  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Product>> getProductsPaginated({
    required int page,
    required int pageSize,
    String orderBy = 'nome ASC',
  }) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    final rows = await db.query(
      'products',
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> addSyncOnCreate(Product product) async {
    await SyncQueue.instance.addSync(
      action: SyncAction.create,
      tableName: 'products',
      data: product.toMap(),
    );
  }

  Future<void> addSyncOnUpdate(Product product) async {
    await SyncQueue.instance.addSync(
      action: SyncAction.update,
      tableName: 'products',
      data: product.toMap(),
    );
  }

  Future<void> addSyncOnDelete(int id) async {
    await SyncQueue.instance.addSync(
      action: SyncAction.delete,
      tableName: 'products',
      data: {'id': id},
    );
  }
}
