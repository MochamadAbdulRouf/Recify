import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/backup/backup_manager.dart';
import '../../domain/export/report_exporter.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceRepository _repository = FinanceRepository();

  List<WalletModel> _wallets = [];
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];

  String? _selectedWalletId;
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;

  List<WalletModel> get wallets => _wallets;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;

  String? get selectedWalletId => _selectedWalletId;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  WalletModel? get activeWallet =>
      _selectedWalletId != null ? _wallets.firstWhere((w) => w.id == _selectedWalletId, orElse: () => _wallets.first) : null;

  double get totalBalance {
    if (activeWallet != null) return activeWallet!.currentBalance;
    return _wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
  }

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
          return t.type == 'INCOME' && d.month == now.month && d.year == now.year;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenseThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
          return t.type == 'EXPENSE' && d.month == now.month && d.year == now.year;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyIncome => totalIncomeThisMonth;
  double get monthlyExpense => totalExpenseThisMonth;
  List<TransactionModel> get recentTransactions => _transactions;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

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
    return _transactions
        .where((t) {
          final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
          return t.categoryId == categoryId && t.type == 'EXPENSE' && d.month == month && d.year == year;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // --- Export Reports (Excel or CSV to Downloads) ---
  Future<String> exportTransactionsReport({required String format}) async {
    if (format == 'excel') {
      final file = await ReportExporter.exportTransactionsToExcel(_transactions);
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
