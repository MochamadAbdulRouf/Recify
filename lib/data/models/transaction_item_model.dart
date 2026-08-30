class TransactionItemModel {
  final String id;
  final String transactionId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? categoryId;

  TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.itemName,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'category_id': categoryId,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      itemName: map['item_name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['category_id'] as String?,
    );
  }
}
