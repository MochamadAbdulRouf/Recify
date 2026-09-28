import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../core/utils/trend_calculator.dart';
import '../../domain/backup/backup_manager.dart';
import '../../domain/export/report_exporter.dart';
import '../../domain/notifications/notification_builder.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceRepository _repository = FinanceRepository();

  static const _kReadNotifs = 'read_notification_ids';
  static const _kRecentSearches = 'recent_searches';
  static const int _maxRecentSearches = 5;

  List<WalletModel> _wallets = [];
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];

  String? _selectedWalletId;
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;

  Set<String> _readNotifIds = {};
  List<String> _recentSearches = [];

  List<WalletModel> get wallets => _wallets;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;

  String? get selectedWalletId => _selectedWalletId;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // --- Notifications (derived in-memory feed, no push, no server) ---

  List<AppNotification> get notifications => NotificationBuilder.build(
        transactions: _transactions,
        budgets: _budgets,
        categories: _categories,
        now: DateTime.now(),
      );

  int get unreadNotificationCount =>
      notifications.where((n) => !_readNotifIds.contains(n.id)).length;

  bool isNotificationRead(String id) => _readNotifIds.contains(id);

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  WalletModel? get activeWallet => _selectedWalletId != null
      ? _wallets.firstWhere((w) => w.id == _selectedWalletId,
          orElse: () => _wallets.first)
      : null;

  double get totalBalance {
    if (activeWallet != null) return activeWallet!.currentBalance;
    return _wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
  }

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return _transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      return t.type == 'INCOME' && d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenseThisMonth {
    final now = DateTime.now();
    return _transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      return t.type == 'EXPENSE' && d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyIncome => totalIncomeThisMonth;
  double get monthlyExpense => totalExpenseThisMonth;
  List<TransactionModel> get recentTransactions => _transactions;

  /// Weekly balance trend: this week's net flow (income − expense) as a share
  /// of the current wallet balance. Renders as a percent, or as a nominal
  /// amount when the percent would round to 0.0%.
  BalanceTrend get weeklyBalanceTrend => TrendCalculator.weeklyBalanceTrend(
        transactions: _transactions,
        currentBalance: totalBalance,
        now: DateTime.now(),
      );

  /// Timestamp of the newest record (creation time) — for "Updated X ago".
  int? get lastDataTimestamp {
    if (_transactions.isEmpty) return null;
    return _transactions
        .map((t) => t.createdAt)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Records captured today — drives the hero card's second status pill.
  int get todayCount {
    final now = DateTime.now();
    return _transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.createdAt);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  /// Biggest expense category this month, for the analytics insight card.
  ({String name, double amount, int percent})? get topExpenseCategory {
    final now = DateTime.now();
    final byCategory = <String, double>{};
    var total = 0.0;
    for (final t in _transactions) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      if (t.type != 'EXPENSE' || d.month != now.month || d.year != now.year) {
        continue;
      }
      final name = t.category?.name ?? 'Umum';
      byCategory[name] = (byCategory[name] ?? 0) + t.amount;
      total += t.amount;
    }
    if (byCategory.isEmpty || total <= 0) return null;
    final top = byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (
      name: top.key,
      amount: top.value,
      percent: ((top.value / total) * 100).round(),
    );
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _readNotifIds = (prefs.getStringList(_kReadNotifs) ?? const []).toSet();
    _recentSearches = prefs.getStringList(_kRecentSearches) ?? [];

    _wallets = await _repository.getWallets();
    _categories = await _repository.getCategories();
    final now = DateTime.now();
    _budgets = await _repository.getBudgets(now.month, now.year);
    await refreshTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    _transactions = await _repository.getTransactions(
      walletId: _selectedWalletId,
      categoryId: _selectedCategoryId,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    _wallets = await _repository.getWallets();
    notifyListeners();
  }

  void selectWallet(String? walletId) {
    _selectedWalletId = walletId;
    refreshTransactions();
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    refreshTransactions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshTransactions();
  }

  // --- Notification read state (persisted, no DB table) ---

  Future<void> markNotificationRead(String id) async {
    if (!_readNotifIds.add(id)) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReadNotifs, _readNotifIds.toList());
  }

  Future<void> markAllNotificationsRead() async {
    _readNotifIds = notifications.map((n) => n.id).toSet();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReadNotifs, _readNotifIds.toList());
  }

  // --- Recent searches ---

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    _recentSearches
      ..removeWhere((e) => e.toLowerCase() == q.toLowerCase())
      ..insert(0, q);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentSearches, _recentSearches);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentSearches);
  }

  // --- Transactions ---
  Future<void> addTransaction({
    required TransactionModel transaction,
    List<TransactionItemModel> items = const [],
  }) async {
    await _repository.recordTransaction(transaction, items);
    await loadInitialData();
  }

  Future<void> saveTransaction(
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) async {
    await _repository.recordTransaction(transaction, items);
    await loadInitialData();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await _repository.deleteTransaction(transaction);
    await loadInitialData();
  }

  // --- Wallets Management ---
  Future<void> addWallet(WalletModel wallet) async {
    await _repository.addWallet(wallet);
    await loadInitialData();
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _repository.updateWallet(wallet);
    await loadInitialData();
  }

  Future<void> deleteWallet(String id) async {
    await _repository.deleteWallet(id);
    await loadInitialData();
  }

  // --- Categories Management ---
  Future<void> addCategory(CategoryModel category) async {
    await _repository.addCategory(category);
    await loadInitialData();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadInitialData();
  }

  // --- Budgets ---
  Future<void> setBudget(BudgetModel budget) async {
    await _repository.setBudget(budget);
    final now = DateTime.now();
    _budgets = await _repository.getBudgets(now.month, now.year);
    notifyListeners();
  }

  double getCategorySpending(String categoryId, int month, int year) {
    return _transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      return t.categoryId == categoryId &&
          t.type == 'EXPENSE' &&
          d.month == month &&
          d.year == year;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// This month's budget for a category, or null when unset.
  ///
  /// Clearing a budget stores limit 0 rather than deleting the row — every
  /// consumer (this getter, the notification builder, the settings sheet)
  /// already treats 0 as "no budget", so no delete path is needed.
  BudgetModel? budgetFor(String categoryId) {
    for (final b in _budgets) {
      if (b.categoryId == categoryId && b.monthlyLimit > 0) return b;
    }
    return null;
  }

  // --- Export Reports (Excel or CSV to Downloads) ---
  Future<String> exportTransactionsReport({required String format}) async {
    if (format == 'excel') {
      final file =
          await ReportExporter.exportTransactionsToExcel(_transactions);
      return file.path;
    } else {
      final file = await ReportExporter.exportTransactionsToCsv(_transactions);
      return file.path;
    }
  }

  Future<String> exportCsvFile() async {
    return await exportTransactionsReport(format: 'csv');
  }

  // --- Backup & Restore ---
  Future<String> createBackup() async {
    final file = await BackupManager.createBackupFile();
    return file.path;
  }

  Future<void> restoreBackup(File file) async {
    await BackupManager.restoreFromBackupFile(file);
    await loadInitialData();
  }
}
