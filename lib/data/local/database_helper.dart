import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Wallets table
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
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
        wallet_id TEXT NOT NULL,
        category_id TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
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
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(transaction_date);');
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id);');
    await db.execute('CREATE INDEX idx_items_transaction ON transaction_items(transaction_id);');
    await db.execute('CREATE INDEX idx_budgets_period ON budgets(year, month);');

    // Populate default seed data
    for (final wallet in SeedData.defaultWallets) {
      await db.insert('wallets', wallet.toMap());
    }
    for (final cat in SeedData.defaultCategories) {
      await db.insert('categories', cat.toMap());
    }

    final now = DateTime.now();
    final defaultBudgets = [
      BudgetModel(
        id: 'b_groceries_${now.month}',
        categoryId: 'cat_groceries',
        monthlyLimit: 2500000.0,
        month: now.month,
        year: now.year,
      ),
      BudgetModel(
        id: 'b_food_${now.month}',
        categoryId: 'cat_food',
        monthlyLimit: 1800000.0,
        month: now.month,
        year: now.year,
      ),
      BudgetModel(
        id: 'b_transport_${now.month}',
        categoryId: 'cat_transport',
        monthlyLimit: 800000.0,
        month: now.month,
        year: now.year,
      ),
    ];
    for (final b in defaultBudgets) {
      await db.insert('budgets', b.toMap());
    }
  }

  // --- Wallets CRUD ---
  Future<List<WalletModel>> getWallets() async {
    final db = await instance.database;
    final result = await db.query('wallets', orderBy: 'created_at ASC');
    return result.map((json) => WalletModel.fromMap(json)).toList();
  }

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await instance.database;
    return await db.insert('wallets', wallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final db = await instance.database;
    return await db.update('wallets', wallet.toMap(), where: 'id = ?', whereArgs: [wallet.id]);
  }

  Future<int> deleteWallet(String id) async {
    final db = await instance.database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Categories CRUD ---
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await instance.database;
    final result = type != null
        ? await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC')
        : await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Transactions & Items (ACID Transaction) ---
  Future<void> recordTransaction(TransactionModel tx, List<TransactionItemModel> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in items) {
        await txn.insert('transaction_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final delta = tx.type == 'EXPENSE' ? -tx.amount : (tx.type == 'INCOME' ? tx.amount : 0.0);
      await txn.rawUpdate(
        'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ?',
        [delta, tx.walletId],
      );
    });
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [tx.id]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);

      final reverseDelta = tx.type == 'EXPENSE' ? tx.amount : (tx.type == 'INCOME' ? -tx.amount : 0.0);
      await txn.rawUpdate(
        'UPDATE wallets SET current_balance = current_balance + ? WHERE id = ?',
        [reverseDelta, tx.walletId],
      );
    });
  }

  Future<List<TransactionModel>> getAllTransactions({String? walletId, String? categoryId, String? searchQuery}) async {
    final db = await instance.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (walletId != null) {
      whereClause += 't.wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 't.category_id = ?';
      whereArgs.add(categoryId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(t.merchant_name LIKE ? OR t.notes LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final query = '''
      SELECT 
        t.*,
        w.name AS wallet_name, w.type AS wallet_type, w.current_balance AS wallet_current_balance, w.initial_balance AS wallet_initial_balance, w.created_at AS wallet_created_at,
        c.name AS category_name, c.type AS category_type, c.icon AS category_icon, c.color AS category_color
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      LEFT JOIN categories c ON t.category_id = c.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY t.transaction_date DESC
    ''';

    final result = await db.rawQuery(query, whereArgs);

    List<TransactionModel> transactions = [];
    for (final row in result) {
      final txId = row['id'] as String;
      final itemsResult = await db.query('transaction_items', where: 'transaction_id = ?', whereArgs: [txId]);
      final items = itemsResult.map((i) => TransactionItemModel.fromMap(i)).toList();

      WalletModel? wallet;
      if (row['wallet_name'] != null) {
        wallet = WalletModel(
          id: row['wallet_id'] as String,
          name: row['wallet_name'] as String,
          type: row['wallet_type'] as String,
          initialBalance: (row['wallet_initial_balance'] as num?)?.toDouble() ?? 0.0,
          currentBalance: (row['wallet_current_balance'] as num?)?.toDouble() ?? 0.0,
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

      transactions.add(TransactionModel.fromMap(row, wallet: wallet, category: category, items: items));
    }
    return transactions;
  }

  // --- Budgets CRUD ---
  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final db = await instance.database;
    final result = await db.query('budgets', where: 'month = ? AND year = ?', whereArgs: [month, year]);
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<int> setBudget(BudgetModel budget) async {
    final db = await instance.database;
    return await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Raw Data for Backup ---
  Future<Map<String, dynamic>> getAllDataForBackup() async {
    final db = await instance.database;
    return {
      'wallets': await db.query('wallets'),
      'categories': await db.query('categories'),
      'transactions': await db.query('transactions'),
      'transaction_items': await db.query('transaction_items'),
      'budgets': await db.query('budgets'),
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
