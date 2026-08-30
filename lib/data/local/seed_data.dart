import '../models/category_model.dart';
import '../models/wallet_model.dart';

class SeedData {
  static List<WalletModel> get defaultWallets => [
        WalletModel(
          id: 'wallet_cash',
          name: 'Dompet Tunai',
          type: 'CASH',
          initialBalance: 500000.0,
          currentBalance: 500000.0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        WalletModel(
          id: 'wallet_bca',
          name: 'BCA Main Account',
          type: 'BANK',
          initialBalance: 15000000.0,
          currentBalance: 15000000.0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        WalletModel(
          id: 'wallet_gopay',
          name: 'GoPay / E-Wallet',
          type: 'E_WALLET',
          initialBalance: 750000.0,
          currentBalance: 750000.0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

  static List<CategoryModel> get defaultCategories => [
        CategoryModel(
          id: 'cat_groceries',
          name: 'Groceries',
          type: 'EXPENSE',
          icon: 'shopping_cart',
          color: '#10B981',
        ),
        CategoryModel(
          id: 'cat_food',
          name: 'Makan & Minum',
          type: 'EXPENSE',
          icon: 'restaurant',
          color: '#F59E0B',
        ),
        CategoryModel(
          id: 'cat_transport',
          name: 'Transportasi',
          type: 'EXPENSE',
          icon: 'directions_car',
          color: '#3B82F6',
        ),
        CategoryModel(
          id: 'cat_shopping',
          name: 'Belanja',
          type: 'EXPENSE',
          icon: 'shopping_bag',
          color: '#EC4899',
        ),
        CategoryModel(
          id: 'cat_bills',
          name: 'Tagihan & Utilitas',
          type: 'EXPENSE',
          icon: 'receipt_long',
          color: '#8B5CF6',
        ),
        CategoryModel(
          id: 'cat_health',
          name: 'Kesehatan',
          type: 'EXPENSE',
          icon: 'medical_services',
          color: '#EF4444',
        ),
        CategoryModel(
          id: 'cat_entertainment',
          name: 'Hiburan',
          type: 'EXPENSE',
          icon: 'movie',
          color: '#6366F1',
        ),
        CategoryModel(
          id: 'cat_salary',
          name: 'Gaji & Pemasukan',
          type: 'INCOME',
          icon: 'payments',
          color: '#10B981',
        ),
        CategoryModel(
          id: 'cat_investment',
          name: 'Investasi / Pasif',
          type: 'INCOME',
          icon: 'trending_up',
          color: '#06B6D4',
        ),
      ];
}
