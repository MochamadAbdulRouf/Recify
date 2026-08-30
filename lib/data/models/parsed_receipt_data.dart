class ParsedReceiptItem {
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? suggestedCategoryId;

  ParsedReceiptItem({
    required this.itemName,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    this.suggestedCategoryId,
  });

  ParsedReceiptItem copyWith({
    String? itemName,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? suggestedCategoryId,
  }) {
    return ParsedReceiptItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
    );
  }
}

class ParsedReceiptData {
  final String merchantName;
  final String suggestedCategory;
  final DateTime transactionDate;
  final String currency;
  final String paymentMethodDetected;
  final List<ParsedReceiptItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final String rawText;
  final String? localImageTempPath;

  ParsedReceiptData({
    this.merchantName = '',
    this.suggestedCategory = 'cat_groceries',
    required this.transactionDate,
    this.currency = 'IDR',
    this.paymentMethodDetected = 'CASH',
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.grandTotal = 0.0,
    this.rawText = '',
    this.localImageTempPath,
  });

  ParsedReceiptData copyWith({
    String? merchantName,
    String? suggestedCategory,
    DateTime? transactionDate,
    String? currency,
    String? paymentMethodDetected,
    List<ParsedReceiptItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? grandTotal,
    String? rawText,
    String? localImageTempPath,
  }) {
    return ParsedReceiptData(
      merchantName: merchantName ?? this.merchantName,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      transactionDate: transactionDate ?? this.transactionDate,
      currency: currency ?? this.currency,
      paymentMethodDetected: paymentMethodDetected ?? this.paymentMethodDetected,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      rawText: rawText ?? this.rawText,
      localImageTempPath: localImageTempPath ?? this.localImageTempPath,
    );
  }
}
