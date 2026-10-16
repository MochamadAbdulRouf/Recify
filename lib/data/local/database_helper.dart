import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/wallet_delta.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _migrateDB,
      // SQLite default OFF; tanpa ini ON DELETE RESTRICT/CASCADE di schema
      // cuma hiasan — dompet berisi transaksi bisa kehapus.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Migrasi v1 → v2: skema multi-akun + HAPUS BERSIH data anonim lama.
  /// (Keputusan produk: tidak ada warisan data pra-login.)
  /// Migrasi v2 → v3: penanda "sudah pernah login manual" per akun.
  Future _migrateDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          salt TEXT NOT NULL,
          name TEXT NOT NULL,
          avatar_path TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      for (final table in [
        'wallets',
        'categories',
        'budgets',
        'transactions',
        'transaction_items'
      ]) {
        final cols = await db.rawQuery('PRAGMA table_info($table)');
        final hasUserId = cols.any((c) => c['name'] == 'user_id');
        if (!hasUserId) {
          await db.execute(
              'ALTER TABLE $table ADD COLUMN user_id TEXT NOT NULL DEFAULT \'\'');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_${table}_user ON $table(user_id);');
        }
      }
      // Hapus bersih: semua baris anonim lama tidak punya pemilik sah.
      await db.delete('transaction_items');
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('wallets');
      await db.delete('categories');
    }
    if (oldVersion < 3) {
      final cols = await db.rawQuery('PRAGMA table_info(users)');
      final hasFlag = cols.any((c) => c['name'] == 'has_logged_in');
      if (!hasFlag) {
        await db.execute(
            'ALTER TABLE users ADD COLUMN has_logged_in INTEGER NOT NULL DEFAULT 0');
      }
    }
    // Migrasi v3 → v4: kolom mata uang untuk fitur multi-currency.
    if (oldVersion < 4) {
      final cols = await db.rawQuery('PRAGMA table_info(transactions)');
      final hasCurrency = cols.any((c) => c['name'] == 'currency');
      if (!hasCurrency) {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN currency TEXT NOT NULL DEFAULT 'IDR'");
      }
    }
  }

  Future _createDB(Database db, int version) async {
    // 0. Users table (akun lokal, multi-akun per perangkat)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        name TEXT NOT NULL,
        avatar_path TEXT,
        has_logged_in INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 1. Wallets table
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 2. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT
      )
    ''');

    // 3. Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 4. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        category_id TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'IDR',
        transaction_date INTEGER NOT NULL,
        merchant_name TEXT,
        receipt_image_path TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE RESTRICT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 5. Transaction Items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        transaction_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        category_id TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Indexes for high query performance
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(transaction_date);');
    await db.execute(
        'CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);');
    await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions(category_id);');
    await db.execute(
        'CREATE INDEX idx_items_transaction ON transaction_items(transaction_id);');
    await db
        .execute('CREATE INDEX idx_budgets_period ON budgets(year, month);');
    await db.execute('CREATE INDEX idx_wallets_user ON wallets(user_id);');
    await db
        .execute('CREATE INDEX idx_categories_user ON categories(user_id);');
    await db.execute('CREATE INDEX idx_budgets_user ON budgets(user_id);');
    await db.execute(
        'CREATE INDEX idx_transactions_user ON transactions(user_id);');
    await db
        .execute('CREATE INDEX idx_items_user ON transaction_items(user_id);');

    // TIDAK ada seed global: tiap akun baru di-seed terpisah
    // via seedNewUserData() agar ruang data antar-akun steril.
  }

  // ── Users CRUD ──
  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('users',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await instance.database;
    final result =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  /// Semua akun terdaftar di perangkat, tertua dulu (untuk switcher).
  Future<List<UserModel>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users', orderBy: 'created_at ASC');
    return result.map((row) => UserModel.fromMap(row)).toList();
  }

  /// Cari akun berdasarkan nama persis (case-insensitive) untuk login
  /// pakai username. Kembaran nama: ambil yang tertua (deterministik).
  Future<UserModel?> getUserByName(String name) async {
    final db = await instance.database;
    final result = await db.query('users',
        where: 'LOWER(name) = ?',
        whereArgs: [name.trim().toLowerCase()],
        orderBy: 'created_at ASC',
        limit: 1);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  /// Tandai akun sudah pernah login manual (syarat pindah langsung).
  Future<int> setHasLoggedIn(String id) async {
    final db = await instance.database;
    return await db.update('users', {'has_logged_in': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateUserProfile(String id,
      {String? name, String? avatarPath, bool clearAvatar = false}) async {
    final db = await instance.database;
    final patch = <String, Object?>{};
    if (name != null) patch['name'] = name;
    if (clearAvatar) {
      patch['avatar_path'] = null;
    } else if (avatarPath != null) {
      patch['avatar_path'] = avatarPath;
    }
    if (patch.isEmpty) return 0;
    return await db.update('users', patch, where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus akun + SELURUH data miliknya (akun lain tak tersentuh).
  Future<void> deleteUserWithData(String userId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_items',
          where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('wallets', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  /// Seed fresh khusus akun baru: template kategori dipertahankan,
  /// struktur dompet default dipertahankan tapi SEMUA saldo = 0.
  /// Budget tidak di-seed (user atur sendiri).
  Future<void> seedNewUserData(String userId) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (final wallet in SeedData.defaultWallets) {
        final map = wallet.toMap()
          ..['id'] = 'w_${userId}_${wallet.id}'
          ..['user_id'] = userId
          ..['initial_balance'] = 0.0
          ..['current_balance'] = 0.0
          ..['created_at'] = now;
        await txn.insert('wallets', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final cat in SeedData.defaultCategories) {
        final map = cat.toMap()
          ..['id'] = 'c_${userId}_${cat.id}'
          ..['user_id'] = userId;
        await txn.insert('categories', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- Wallets CRUD (terfilter pemilik) ---
  Future<List<WalletModel>> getWallets(String userId) async {
    final db = await instance.database;
    final result = await db.query('wallets',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at ASC');
    return result.map((json) => WalletModel.fromMap(json)).toList();
  }

  Future<int> insertWallet(String userId, WalletModel wallet) async {
    final db = await instance.database;
    final map = wallet.toMap()..['user_id'] = userId;
    return await db.insert('wallets', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWallet(String userId, WalletModel wallet) async {
    final db = await instance.database;
    final map = wallet.toMap()..['user_id'] = userId;
    return await db.update('wallets', map,
        where: 'id = ? AND user_id = ?', whereArgs: [wallet.id, userId]);
  }

  Future<int> deleteWallet(String userId, String id) async {
    final db = await instance.database;
    return await db.delete('wallets',
        where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  // --- Categories CRUD (terfilter pemilik) ---
  Future<List<CategoryModel>> getCategories(String userId,
      {String? type}) async {
    final db = await instance.database;
    final result = type != null
        ? await db.query('categories',
            where: 'user_id = ? AND type = ?',
            whereArgs: [userId, type],
            orderBy: 'name ASC')
        : await db.query('categories',
            where: 'user_id = ?', whereArgs: [userId], orderBy: 'name ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> insertCategory(String userId, CategoryModel category) async {
    final db = await instance.database;
    final map = category.toMap()..['user_id'] = userId;
    return await db.insert('categories', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCategory(String userId, CategoryModel category) async {
    final db = await instance.database;
    final map = category.toMap()..['user_id'] = userId;
    return await db.update('categories', map,
        where: 'id = ? AND user_id = ?', whereArgs: [category.id, userId]);
  }

  Future<int> deleteCategory(String userId, String id) async {
    final db = await instance.database;
    return await db.delete('categories',
        where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  // --- Transactions & Items (ACID Transaction, terfilter pemilik) ---
  Future<void> recordTransaction(String userId, TransactionModel tx,
      List<TransactionItemModel> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final txMap = tx.toMap()..['user_id'] = userId;
      await txn.insert('transactions', txMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in items) {
        final itemMap = item.toMap()
          ..['user_id'] = userId
          ..['transaction_id'] = tx.id;
        await txn.insert('transaction_items', itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final delta = WalletDelta.deltaFor(tx.type, tx.amount);
      await txn.rawUpdate(
        'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ? AND user_id = ?',
        [delta, tx.walletId, userId],
      );
    });
  }

  /// Edit transaksi: balikkan dampak lama, terapkan dampak baru, atomik.
  /// Kalau pindah dompet, reverse di dompet lama + apply di dompet baru.
  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTx,
    TransactionModel newTx,
    List<TransactionItemModel> items,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_items',
          where: 'transaction_id = ? AND user_id = ?',
          whereArgs: [newTx.id, userId]);
      final newMap = newTx.toMap()..['user_id'] = userId;
      await txn.insert('transactions', newMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in items) {
        final itemMap = item.toMap()
          ..['user_id'] = userId
          ..['transaction_id'] = newTx.id;
        await txn.insert('transaction_items', itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      if (oldTx.walletId == newTx.walletId) {
        final net = WalletDelta.netForUpdate(
          oldType: oldTx.type,
          oldAmount: oldTx.amount,
          newType: newTx.type,
          newAmount: newTx.amount,
        );
        await txn.rawUpdate(
          'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ? AND user_id = ?',
          [net, newTx.walletId, userId],
        );
      } else {
        await txn.rawUpdate(
          'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ? AND user_id = ?',
          [
            -WalletDelta.deltaFor(oldTx.type, oldTx.amount),
            oldTx.walletId,
            userId
          ],
        );
        await txn.rawUpdate(
          'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ? AND user_id = ?',
          [
            WalletDelta.deltaFor(newTx.type, newTx.amount),
            newTx.walletId,
            userId
          ],
        );
      }
    });
  }

  Future<void> deleteTransaction(String userId, TransactionModel tx) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_items',
          where: 'transaction_id = ? AND user_id = ?',
          whereArgs: [tx.id, userId]);
      await txn.delete('transactions',
          where: 'id = ? AND user_id = ?', whereArgs: [tx.id, userId]);

      final reverseDelta = -WalletDelta.deltaFor(tx.type, tx.amount);
      await txn.rawUpdate(
        'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ? AND user_id = ?',
        [reverseDelta, tx.walletId, userId],
      );
    });
  }

  Future<List<TransactionModel>> getAllTransactions(String userId,
      {String? walletId, String? categoryId, String? searchQuery}) async {
    final db = await instance.database;

    String whereClause = 't.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (walletId != null) {
      whereClause += ' AND t.wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (categoryId != null) {
      whereClause += ' AND t.category_id = ?';
      whereArgs.add(categoryId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (t.merchant_name LIKE ? OR t.notes LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final query = '''
      SELECT 
        t.*,
        w.name AS wallet_name, w.type AS wallet_type, w.current_balance AS wallet_current_balance, w.initial_balance AS wallet_initial_balance, w.created_at AS wallet_created_at,
        c.name AS category_name, c.type AS category_type, c.icon AS category_icon, c.color AS category_color
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id AND w.user_id = t.user_id
      LEFT JOIN categories c ON t.category_id = c.id AND c.user_id = t.user_id
      WHERE $whereClause
      ORDER BY t.transaction_date DESC
    ''';

    final result = await db.rawQuery(query, whereArgs);

    List<TransactionModel> transactions = [];
    for (final row in result) {
      final txId = row['id'] as String;
      final itemsResult = await db.query('transaction_items',
          where: 'transaction_id = ? AND user_id = ?',
          whereArgs: [txId, userId]);
      final items =
          itemsResult.map((i) => TransactionItemModel.fromMap(i)).toList();

      WalletModel? wallet;
      if (row['wallet_name'] != null) {
        wallet = WalletModel(
          id: row['wallet_id'] as String,
          name: row['wallet_name'] as String,
          type: row['wallet_type'] as String,
          initialBalance:
              (row['wallet_initial_balance'] as num?)?.toDouble() ?? 0.0,
          currentBalance:
              (row['wallet_current_balance'] as num?)?.toDouble() ?? 0.0,
          createdAt: row['wallet_created_at'] as int? ?? 0,
        );
      }

      CategoryModel? category;
      if (row['category_name'] != null) {
        category = CategoryModel(
          id: row['category_id'] as String,
          name: row['category_name'] as String,
          type: row['category_type'] as String,
          icon: row['category_icon'] as String? ?? 'category',
          color: row['category_color'] as String? ?? '#2F6BFF',
        );
      }

      transactions.add(TransactionModel.fromMap(row,
          wallet: wallet, category: category, items: items));
    }
    return transactions;
  }

  // --- Budgets CRUD (terfilter pemilik) ---
  Future<List<BudgetModel>> getBudgets(
      String userId, int month, int year) async {
    final db = await instance.database;
    final result = await db.query('budgets',
        where: 'user_id = ? AND month = ? AND year = ?',
        whereArgs: [userId, month, year]);
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<int> setBudget(String userId, BudgetModel budget) async {
    final db = await instance.database;
    final map = budget.toMap()..['user_id'] = userId;
    return await db.insert('budgets', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Raw Data for Backup (hanya milik akun aktif) ---
  Future<Map<String, dynamic>> getAllDataForBackup(String userId) async {
    final db = await instance.database;
    Future<List<Map<String, dynamic>>> scoped(String table) =>
        db.query(table, where: 'user_id = ?', whereArgs: [userId]);
    return {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'user_id': userId,
      'wallets': await scoped('wallets'),
      'categories': await scoped('categories'),
      'transactions': await scoped('transactions'),
      'transaction_items': await scoped('transaction_items'),
      'budgets': await scoped('budgets'),
    };
  }

  // --- Restore from Backup (hanya timpa data akun aktif) ---
  Future<void> restoreAllData(String userId, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Clear existing tables — HANYA milik akun ini.
      await txn.delete('transaction_items',
          where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('wallets', where: 'user_id = ?', whereArgs: [userId]);

      Future<void> restoreList(String key, String table) async {
        if (data[key] is List) {
          for (final item in data[key]) {
            if (item is Map<String, dynamic>) {
              final row = Map<String, dynamic>.from(item)..['user_id'] = userId;
              await txn.insert(table, row,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Urutan penting untuk FK: wallets & categories dulu.
      await restoreList('wallets', 'wallets');
      await restoreList('categories', 'categories');
      await restoreList('budgets', 'budgets');
      await restoreList('transactions', 'transactions');
      await restoreList('transaction_items', 'transaction_items');
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
