import 'category_model.dart';
import 'transaction_item_model.dart';
import 'wallet_model.dart';

class TransactionModel {
  final String id;
  final String walletId;
  final String? categoryId;
  final String type; // 'EXPENSE', 'INCOME', 'TRANSFER'
  final double amount;
  final int transactionDate;
  final String? merchantName;
  final String? receiptImagePath;
  final String? notes;
  final int createdAt;

  // Joined fields
  final WalletModel? wallet;
  final CategoryModel? category;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.merchantName,
    this.receiptImagePath,
    this.notes,
    required this.createdAt,
    this.wallet,
    this.category,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate,
      'merchant_name': merchantName,
      'receipt_image_path': receiptImagePath,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    WalletModel? wallet,
    CategoryModel? category,
    List<TransactionItemModel> items = const [],
  }) {
    return TransactionModel(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: map['transaction_date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      merchantName: map['merchant_name'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      wallet: wallet,
      category: category,
      items: items,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? walletId,
    String? categoryId,
    String? type,
    double? amount,
    int? transactionDate,
    String? merchantName,
    String? receiptImagePath,
    String? notes,
    int? createdAt,
    WalletModel? wallet,
    CategoryModel? category,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      merchantName: merchantName ?? this.merchantName,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      wallet: wallet ?? this.wallet,
      category: category ?? this.category,
      items: items ?? this.items,
    );
  }
}
