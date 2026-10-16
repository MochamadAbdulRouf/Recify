import '../local/database_helper.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Semua akses data keuangan wajib membawa [userId] akun aktif —
/// tidak ada query lintas akun di seluruh aplikasi.
class FinanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Wallets
  Future<List<WalletModel>> getWallets(String userId) =>
      _dbHelper.getWallets(userId);
  Future<int> addWallet(String userId, WalletModel wallet) =>
      _dbHelper.insertWallet(userId, wallet);
  Future<int> updateWallet(String userId, WalletModel wallet) =>
      _dbHelper.updateWallet(userId, wallet);
  Future<int> deleteWallet(String userId, String id) =>
      _dbHelper.deleteWallet(userId, id);

  // Categories
  Future<List<CategoryModel>> getCategories(String userId, {String? type}) =>
      _dbHelper.getCategories(userId, type: type);
  Future<int> addCategory(String userId, CategoryModel category) =>
      _dbHelper.insertCategory(userId, category);
  Future<int> updateCategory(String userId, CategoryModel category) =>
      _dbHelper.updateCategory(userId, category);
  Future<int> deleteCategory(String userId, String id) =>
      _dbHelper.deleteCategory(userId, id);

  // Transactions
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? walletId,
    String? categoryId,
    String? searchQuery,
  }) =>
      _dbHelper.getAllTransactions(
        userId,
        walletId: walletId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

  Future<void> recordTransaction(
    String userId,
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) =>
      _dbHelper.recordTransaction(userId, transaction, items);

  Future<void> deleteTransaction(String userId, TransactionModel transaction) =>
      _dbHelper.deleteTransaction(userId, transaction);

  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
    List<TransactionItemModel> items,
  ) =>
      _dbHelper.updateTransaction(
          userId, oldTransaction, newTransaction, items);

  // Budgets
  Future<List<BudgetModel>> getBudgets(String userId, int month, int year) =>
      _dbHelper.getBudgets(userId, month, year);

  Future<int> setBudget(String userId, BudgetModel budget) =>
      _dbHelper.setBudget(userId, budget);

  // Backup & Restore (skop akun aktif)
  Future<Map<String, dynamic>> getAllDataForBackup(String userId) =>
      _dbHelper.getAllDataForBackup(userId);

  Future<void> restoreAllData(String userId, Map<String, dynamic> data) =>
      _dbHelper.restoreAllData(userId, data);
}
