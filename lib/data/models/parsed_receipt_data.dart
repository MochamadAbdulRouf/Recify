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

  /// Validation status: 'valid', 'warning', 'needs_review', or null (not validated yet)
  final String? validationStatus;

  /// Which parser produced this data: 'gemini', 'regex', or 'manual'
  final String? parserSource;

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
    this.validationStatus,
    this.parserSource,
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
    String? validationStatus,
    String? parserSource,
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
      validationStatus: validationStatus ?? this.validationStatus,
      parserSource: parserSource ?? this.parserSource,
    );
  }

  /// Factory constructor to create ParsedReceiptData from Gemini API JSON response.
  ///
  /// Expected JSON schema:
  /// ```json
  /// {
  ///   "merchant": "string",
  ///   "date": "YYYY-MM-DD" | null,
  ///   "category": "cat_groceries",
  ///   "payment_method": "CASH",
  ///   "items": [{"name": "string", "qty": 1, "price": 15000}],
  ///   "subtotal": 15000,
  ///   "tax": 0,
  ///   "discount": 0,
  ///   "grand_total": 15000
  /// }
  /// ```
  factory ParsedReceiptData.fromGeminiJson(
    Map<String, dynamic> json, {
    String? rawText,
    String? imagePath,
  }) {
    // Parse date from "YYYY-MM-DD" string
    DateTime transactionDate = DateTime.now();
    final dateStr = json['date'] as String?;
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        transactionDate = DateTime.parse(dateStr);
        // Sanity check: date should be reasonable
        if (transactionDate.isBefore(DateTime(2020)) ||
            transactionDate.isAfter(DateTime.now().add(const Duration(days: 30)))) {
          transactionDate = DateTime.now();
        }
      } catch (_) {
        transactionDate = DateTime.now();
      }
    }

    // Parse items
    final itemsList = <ParsedReceiptItem>[];
    final rawItems = json['items'] as List<dynamic>? ?? [];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] as String?)?.trim() ?? '';
        final qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;

        if (name.isNotEmpty && price > 0) {
          itemsList.add(ParsedReceiptItem(
            itemName: name,
            quantity: qty,
            unitPrice: qty > 0 ? price / qty : price,
            totalPrice: price,
          ));
        }
      }
    }

    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0.0;
    final tax = (json['tax'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['discount'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (json['grand_total'] as num?)?.toDouble() ?? 0.0;

    return ParsedReceiptData(
      merchantName: (json['merchant'] as String?)?.trim() ?? '',
      suggestedCategory: (json['category'] as String?)?.trim() ?? 'cat_groceries',
      transactionDate: transactionDate,
      currency: 'IDR',
      paymentMethodDetected: (json['payment_method'] as String?)?.trim() ?? 'CASH',
      items: itemsList,
      subtotal: subtotal > 0 ? subtotal : (itemsList.isNotEmpty
          ? itemsList.fold(0.0, (s, i) => s + i.totalPrice)
          : grandTotal),
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      rawText: rawText ?? '',
      localImageTempPath: imagePath,
      parserSource: 'gemini',
    );
  }
}
