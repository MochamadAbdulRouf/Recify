import '../local/database_helper.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class FinanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Wallets
  Future<List<WalletModel>> getWallets() => _dbHelper.getWallets();
  Future<int> addWallet(WalletModel wallet) => _dbHelper.insertWallet(wallet);
  Future<int> updateWallet(WalletModel wallet) => _dbHelper.updateWallet(wallet);
  Future<int> deleteWallet(String id) => _dbHelper.deleteWallet(id);

  // Categories
  Future<List<CategoryModel>> getCategories({String? type}) => _dbHelper.getCategories(type: type);
  Future<int> addCategory(CategoryModel category) => _dbHelper.insertCategory(category);

  // Transactions
  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    String? categoryId,
    String? searchQuery,
  }) =>
      _dbHelper.getAllTransactions(
        walletId: walletId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

  Future<void> recordTransaction(
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) =>
      _dbHelper.recordTransaction(transaction, items);

  Future<void> deleteTransaction(TransactionModel transaction) =>
      _dbHelper.deleteTransaction(transaction);

  // Budgets
  Future<List<BudgetModel>> getBudgets(int month, int year) =>
      _dbHelper.getBudgets(month, year);

  Future<int> setBudget(BudgetModel budget) => _dbHelper.setBudget(budget);

  // Backup Dump
  Future<Map<String, dynamic>> getAllDataForBackup() =>
      _dbHelper.getAllDataForBackup();
}
