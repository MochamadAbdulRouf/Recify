import 'package:intl/intl.dart';
import '../../data/models/parsed_receipt_data.dart';

class IndonesianReceiptParser {
  static const List<Map<String, String>> _merchantKeywordMap = [
    // Groceries / Minimarkets
    {'keyword': 'INDOMARET', 'category': 'cat_groceries'},
    {'keyword': 'ALFAMART', 'category': 'cat_groceries'},
    {'keyword': 'ALFAMIDI', 'category': 'cat_groceries'},
    {'keyword': 'SUPERINDO', 'category': 'cat_groceries'},
    {'keyword': 'HYPERMART', 'category': 'cat_groceries'},
    {'keyword': 'TRANSMART', 'category': 'cat_groceries'},
    {'keyword': 'HERO', 'category': 'cat_groceries'},
    {'keyword': 'FARMERS MARKET', 'category': 'cat_groceries'},
    {'keyword': 'GIANT', 'category': 'cat_groceries'},
    {'keyword': 'LOTTEMART', 'category': 'cat_groceries'},
    {'keyword': 'RANCH MARKET', 'category': 'cat_groceries'},
    {'keyword': 'HARI HARI', 'category': 'cat_groceries'},
    {'keyword': 'CIRCLE K', 'category': 'cat_groceries'},

    // Fuel / Transport
    {'keyword': 'PERTAMINA', 'category': 'cat_transport'},
    {'keyword': 'SPBU', 'category': 'cat_transport'},
    {'keyword': 'SHELL', 'category': 'cat_transport'},
    {'keyword': 'BP', 'category': 'cat_transport'},
    {'keyword': 'VIVO ENERGY', 'category': 'cat_transport'},

    // Food & Dining / Resto
    {'keyword': 'GACOAN', 'category': 'cat_food'},
    {'keyword': 'MIE GACOAN', 'category': 'cat_food'},
    {'keyword': 'ICHIBAN', 'category': 'cat_food'},
    {'keyword': 'SUSHI', 'category': 'cat_food'},
    {'keyword': 'RAMEN', 'category': 'cat_food'},
    {'keyword': 'STARBUCKS', 'category': 'cat_food'},
    {'keyword': 'KFC', 'category': 'cat_food'},
    {'keyword': 'MCDONALD', 'category': 'cat_food'},
    {'keyword': 'MCD', 'category': 'cat_food'},
    {'keyword': 'SOLARIA', 'category': 'cat_food'},
    {'keyword': 'HOKBEN', 'category': 'cat_food'},
    {'keyword': 'PIZZA HUT', 'category': 'cat_food'},
    {'keyword': 'JANJI JIWA', 'category': 'cat_food'},
    {'keyword': 'KOPI KENANGAN', 'category': 'cat_food'},
    {'keyword': 'WARKOP', 'category': 'cat_food'},
    {'keyword': 'RICHEESE', 'category': 'cat_food'},
    {'keyword': 'BURGER KING', 'category': 'cat_food'},
    {'keyword': 'JCOFFEE', 'category': 'cat_food'},
    {'keyword': 'J.CO', 'category': 'cat_food'},
    {'keyword': 'BAKMI GM', 'category': 'cat_food'},
    {'keyword': 'ES TEH', 'category': 'cat_food'},
    {'keyword': 'CHATIME', 'category': 'cat_food'},
    {'keyword': 'MIXUE', 'category': 'cat_food'},
    {'keyword': 'SUBWAY', 'category': 'cat_food'},
    {'keyword': 'DOMINOS', 'category': 'cat_food'},
    {'keyword': 'MARUGAME', 'category': 'cat_food'},
    {'keyword': 'YOSHINOYA', 'category': 'cat_food'},
    {'keyword': 'TA WAN', 'category': 'cat_food'},
    {'keyword': 'D\'COST', 'category': 'cat_food'},
    {'keyword': 'KOI THE', 'category': 'cat_food'},
    {'keyword': 'FORE', 'category': 'cat_food'},
    {'keyword': 'POINT COFFEE', 'category': 'cat_food'},
    {'keyword': 'LAWSON', 'category': 'cat_food'},
    {'keyword': 'FAMILYMART', 'category': 'cat_food'},
    {'keyword': 'BAKSO', 'category': 'cat_food'},
    {'keyword': 'SOTO', 'category': 'cat_food'},
    {'keyword': 'AYAM GEPREK', 'category': 'cat_food'},
    {'keyword': 'PADANG', 'category': 'cat_food'},
    {'keyword': 'RESTO', 'category': 'cat_food'},
    {'keyword': 'RESTORAN', 'category': 'cat_food'},
    {'keyword': 'CAFE', 'category': 'cat_food'},
    {'keyword': 'KAFE', 'category': 'cat_food'},

    // Health / Pharmacy
    {'keyword': 'APOTEK', 'category': 'cat_health'},
    {'keyword': 'KIMIA FARMA', 'category': 'cat_health'},
    {'keyword': 'CENTURY', 'category': 'cat_health'},
    {'keyword': 'GUARDIAN', 'category': 'cat_health'},
    {'keyword': 'WATSON', 'category': 'cat_health'},

    // Shopping
    {'keyword': 'UNIQLO', 'category': 'cat_shopping'},
    {'keyword': 'ZARA', 'category': 'cat_shopping'},
    {'keyword': 'MINISO', 'category': 'cat_shopping'},
    {'keyword': 'GRAMEDIA', 'category': 'cat_shopping'},
    {'keyword': 'ACE HARDWARE', 'category': 'cat_shopping'},
    {'keyword': 'DAISO', 'category': 'cat_shopping'},
    {'keyword': 'MR DIY', 'category': 'cat_shopping'},
  ];

  static const List<String> _subtotalKeywords = [
    'SUB TOTAL',
    'SUBTOTAL',
    'TOTAL HARGA',
    'TOTAL SEBELUM PAJAK',
    'SUB-TOTAL',
  ];

  static const List<String> _taxKeywords = [
    'PAJAK',
    'PPN',
    'PB1',
    'TAX',
    'PPN 11%',
    'PPN 10%',
    'PPN 12%',
    'SERVICE CHARGE',
    'SC ',
  ];

  static const List<String> _discountKeywords = [
    'DISKON',
    'DISCOUNT',
    'HEMAT',
    'POTONGAN',
    'PROMO',
    'VOUCHER',
    'SAVING',
  ];

  /// Lines to skip when extracting receipt items
  static const List<String> _skipItemKeywords = [
    'SUB TOTAL',
    'SUBTOTAL',
    'SUB-TOTAL',
    'GRAND TOTAL',
    'TOTAL BAYAR',
    'TOTAL AKHIR',
    'TOTAL TRANSAKSI',
    'TOTAL PEMBAYARAN',
    'TOTAL BELANJA',
    'BILL',
    'TAGIHAN',
    'NETTO',
    'AMOUNT DUE',
    'TOTAL',
    'JUMLAH',
    'TOTAL ITEM',
    'TOTAL QTY',
    'TOTAL PCS',
    'TOTAL BARIS',
    'ITEM :',
    'QTY :',
    'PAX :',
    'PAX:',
    'TBL ',
    'TABLE',
    'MEJA',
    'SERVER:',
    'SERVER :',
    'KASIR',
    'CASHIER',
    'SHIFT',
    'POS ',
    'POS:',
    'JAM ',
    'WAKTU',
    'TANGGAL',
    'DATE',
    'PAJAK',
    'PPN',
    'PB1',
    'TAX',
    'SERVICE CHARGE',
    'SC ',
    'PEMBULATAN',
    'ROUNDING',
    'DISKON',
    'DISCOUNT',
    'HEMAT',
    'POTONGAN',
    'PROMO',
    'VOUCHER',
    'TUNAI',
    'CASH',
    'KEMBALI',
    'KEMBALIAN',
    'CHANGE',
    'BAYAR',
    'PAYMENT',
    'MEMBER',
    'STRUK',
    'NOTA',
    'RECEIPT',
    'NO.',
    'NOMOR',
    'TOKO',
    'STORE',
    'CABANG',
    'BRANCH',
    'TELP',
    'PHONE',
    'ALAMAT',
    'ADDRESS',
    'NPWP',
    'DEBIT',
    'KREDIT',
    'CREDIT',
    'KARTU',
    'CARD',
    'GOPAY',
    'OVO',
    'DANA',
    'SHOPEEPAY',
    'QRIS',
    'REF',
    'APPROVAL',
    'BATCH',
    'TRACE',
    'TERMINAL',
    'MID',
    'TID',
    'LUNAS',
    'PAID',
    'SELAMAT',
    'WELCOME',
    'TERIMA KASIH',
    'THANK YOU',
    'PRINTED',
  ];

  ParsedReceiptData parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String merchantName = _extractMerchantName(lines);
    String suggestedCategory = _detectCategoryFromMerchant(merchantName);
    final transactionDate = _extractDate(rawText);

    final subtotal = _extractSubtotal(lines);
    final tax = _extractTax(lines);
    final discount = _extractDiscount(lines);
    final items = _extractItems(lines);

    // Extract grand total with items context
    var total = _extractGrandTotal(lines, items);

    // Cross-validation: if total is suspiciously small compared to items sum
    if (items.isNotEmpty) {
      final itemsSum = items.fold(0.0, (sum, i) => sum + i.totalPrice);
      if (itemsSum > 0 && (total < itemsSum * 0.5 || total < 500)) {
        // Total was misparsed (e.g. grabbed 6 or 500), find proper total or fallback to items sum + tax
        final closest = _findClosestTotal(lines, itemsSum);
        total = closest ?? (itemsSum + tax - discount);
      }
    }

    // Category refinement based on detected items
    if (items.isNotEmpty) {
      final refined = _refineCategoryFromItems(items);
      if (refined != null) suggestedCategory = refined;
    }

    if (merchantName.isEmpty && lines.isNotEmpty) {
      merchantName = _fallbackMerchantName(lines);
    }

    return ParsedReceiptData(
      merchantName: merchantName,
      suggestedCategory: suggestedCategory,
      transactionDate: transactionDate,
      currency: 'IDR',
      paymentMethodDetected: _detectPaymentMethod(rawText),
      items: items,
      subtotal: subtotal ?? (items.isNotEmpty ? items.fold(0.0, (s, i) => s + i.totalPrice) : total),
      discount: discount,
      tax: tax,
      grandTotal: total,
      rawText: rawText,
      localImageTempPath: imagePath,
    );
  }

  String _fallbackMerchantName(List<String> lines) {
    return lines.firstWhere(
      (l) =>
          l.length >= 3 &&
          l.length <= 35 &&
          !RegExp(r'[0-9]{5,}').hasMatch(l) &&
          !_isSkipItemLine(l),
      orElse: () => 'Nota Belanja',
    );
  }

  String _extractMerchantName(List<String> lines) {
    for (final line in lines.take(8)) {
      final upper = line.toUpperCase();
      for (final entry in _merchantKeywordMap) {
        if (upper.contains(entry['keyword']!)) {
          return line.trim();
        }
      }
    }
    for (final line in lines.take(4)) {
      if (line.length >= 4 &&
          line.length <= 30 &&
          !RegExp(r'\d').hasMatch(line) &&
          !_isSkipItemLine(line)) {
        return line;
      }
    }
    return '';
  }

  String _detectCategoryFromMerchant(String merchant) {
    final upper = merchant.toUpperCase();
    for (final entry in _merchantKeywordMap) {
      if (upper.contains(entry['keyword']!)) {
        return entry['category']!;
      }
    }
    return 'cat_groceries';
  }

  String? _refineCategoryFromItems(List<ParsedReceiptItem> items) {
    final text = items.map((i) => i.itemName).join(' ').toUpperCase();
    final foodKeywords = [
      'KOPI', 'NASI', 'AYAM', 'BURGER', 'MIE', 'LATTE', 'CAPPUCCINO',
      'ESPRESSO', 'TEH', 'JUICE', 'ROTI', 'DONAT', 'PIZZA', 'RAMEN',
      'SUSHI', 'ROLL', 'TERIYAKI', 'KATSU', 'BENTO', 'SALMON', 'UDON',
      'DIMSUM', 'PANGSIT', 'SIOMAY', 'SAMBAL', 'ES ', 'TEA', 'MINUMAN',
      'DRINK', 'BEVERAGE', 'KENTANG', 'SATE', 'SOTO', 'PASTA', 'STEAK',
      'SHABU', 'GRILL', 'SEAFOOD', 'UDANG', 'IKAN', 'DAGING', 'BEEF',
      'CHICKEN', 'TAHU', 'TEMPE', 'KEJU',
    ];
    if (foodKeywords.any((k) => text.contains(k))) {
      return 'cat_food';
    }

    if (text.contains('BENSIN') ||
        text.contains('PERTALITE') ||
        text.contains('PERTAMAX') ||
        text.contains('SOLAR') ||
        text.contains('DEX') ||
        text.contains('DEXLITE')) {
      return 'cat_transport';
    }

    if (text.contains('OBAT') ||
        text.contains('PARACETAMOL') ||
        text.contains('VITAMIN') ||
        text.contains('IBUPROFEN') ||
        text.contains('MASKER') ||
        text.contains('ANTANGIN')) {
      return 'cat_health';
    }

    return null;
  }

  /// Normalize spaces inside numbers caused by OCR: "77, 500" -> "77,500" or "77 . 500" -> "77.500"
  static String _normalizeNumberSpacing(String text) {
    return text.replaceAllMapped(
      RegExp(r'(\d+)\s*([.,])\s*(\d+)'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );
  }

  /// Check if a line is a quantity/price specification (e.g. "1 x @ 10,000  10,000" or "2 x 9,099")
  bool _isQuantityPriceLine(String line) {
    final clean = _normalizeNumberSpacing(line.trim());
    // Pattern: "1 x @ 10,000 10,000", "2 x @ 9,099", "1 x 10,000", "1x10000", "1 @ 10,000", "@ 10,000"
    if (RegExp(r'^\d+\s*[xX*@]\s*[@]?\s*[\d.,]').hasMatch(clean)) return true;
    // Just price line: "10,000" or "Rp 10.000" or "@ 10.000"
    if (RegExp(r'^[Rr]?[Pp]?\.?\s*@?\s*[\d.,\s]+$').hasMatch(clean)) return true;
    return false;
  }

  bool _isSkipItemLine(String line) {
    final upper = line.toUpperCase();
    return _skipItemKeywords.any((k) => upper.contains(k));
  }

  /// Extract items from receipt lines, handling both single-line and two-line item formats
  List<ParsedReceiptItem> _extractItems(List<String> lines) {
    final result = <ParsedReceiptItem>[];

    // Find likely start of items
    int startIndex = 0;
    for (int i = 0; i < lines.length && i < 10; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('---') ||
          upper.contains('===') ||
          upper.contains('***') ||
          upper.contains('TBL ') ||
          upper.contains('TABLE ') ||
          upper.contains('KASIR') ||
          upper.contains('SHIFT')) {
        startIndex = i + 1;
        break;
      }
    }

    for (int i = startIndex; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = _normalizeNumberSpacing(rawLine);

      // Skip non-item lines
      if (_isSkipItemLine(line)) continue;
      if (RegExp(r'^[-=*_]{3,}$').hasMatch(line.replaceAll(' ', ''))) continue;
      if (line.length < 2) continue;

      // Skip lone quantity/price lines that weren't paired with a previous item name
      if (_isQuantityPriceLine(line)) continue;

      // Strategy A: Two-Line Item Format (e.g. Mie Gacoan)
      // Line i: Item Name (e.g. "MIE GACOAN LV 1" or "UDANG RAMBUTAN")
      // Line i+1: Quantity & Price (e.g. "1 x @ 10,000    10,000" or "2 x @ 9,099    18,198")
      if (i + 1 < lines.length && _isQuantityPriceLine(lines[i + 1])) {
        final nextLine = _normalizeNumberSpacing(lines[i + 1]);
        final parsedTwoLine = _parseTwoLineItem(line, nextLine);
        if (parsedTwoLine != null) {
          result.add(parsedTwoLine);
          i++; // Skip the next line since we consumed it as quantity/price
          continue;
        }
      }

      // Strategy B: Single-Line with leading quantity (e.g. Ichiban Sushi: "1 Beef Teriyaki Ramen    42,000")
      final leadingQtyItem = _tryParseLeadingQty(line);
      if (leadingQtyItem != null) {
        result.add(leadingQtyItem);
        continue;
      }

      // Strategy C: Single-Line with inline quantity (e.g. "INDOMIE 2x3500    7000")
      final inlineQtyItem = _tryParseInlineQty(line);
      if (inlineQtyItem != null) {
        result.add(inlineQtyItem);
        continue;
      }

      // Strategy D: Single-Line with "Rp" prefix (e.g. "INDOMIE GORENG    Rp 3.500")
      final rpItem = _tryParseWithRp(line);
      if (rpItem != null) {
        result.add(rpItem);
        continue;
      }

      // Strategy E: Simple "NAME    PRICE" format
      final simpleItem = _tryParseSimple(line);
      if (simpleItem != null) {
        result.add(simpleItem);
        continue;
      }
    }

    return result;
  }

  /// Parse two-line item: Name on line 1, Qty & Price on line 2
  ParsedReceiptItem? _parseTwoLineItem(String nameLine, String qtyPriceLine) {
    final name = _cleanItemName(nameLine);
    if (name.length < 2 || RegExp(r'^\d+$').hasMatch(name)) return null;

    // Pattern 1: "2 x @ 9,099    18,198" or "1 x @ 10,000    10,000" (qty, unit price, total price)
    final pattern1 = RegExp(
      r'(\d+)\s*[xX*@]\s*[@]?\s*([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s+([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)',
    );
    final m1 = pattern1.firstMatch(qtyPriceLine);
    if (m1 != null) {
      final qty = double.tryParse(m1.group(1) ?? '1') ?? 1.0;
      final unitPrice = _parseNumber(m1.group(2) ?? '');
      final totalPrice = _parseNumber(m1.group(3) ?? '');
      if (_isValidItem(name, totalPrice > 0 ? totalPrice : unitPrice * qty)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: qty,
          unitPrice: unitPrice > 0 ? unitPrice : (totalPrice / qty),
          totalPrice: totalPrice > 0 ? totalPrice : (unitPrice * qty),
        );
      }
    }

    // Pattern 2: "1 x @ 10,000" or "2 x 9,099" (qty and unit price only)
    final pattern2 = RegExp(
      r'(\d+)\s*[xX*@]\s*[@]?\s*([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)',
    );
    final m2 = pattern2.firstMatch(qtyPriceLine);
    if (m2 != null) {
      final qty = double.tryParse(m2.group(1) ?? '1') ?? 1.0;
      final unitPrice = _parseNumber(m2.group(2) ?? '');
      final totalPrice = qty * unitPrice;
      if (_isValidItem(name, totalPrice)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: qty,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
        );
      }
    }

    // Pattern 3: Just price on second line: "10,000" or "Rp 10.000"
    final price = _extractAmountFromLine(qtyPriceLine);
    if (price != null && _isValidItem(name, price)) {
      return ParsedReceiptItem(
        itemName: name,
        quantity: 1.0,
        unitPrice: price,
        totalPrice: price,
      );
    }

    return null;
  }

  /// Single line with leading quantity: "1 Beef Teriyaki Ramen    42,000"
  ParsedReceiptItem? _tryParseLeadingQty(String line) {
    final pattern = RegExp(
      r'^(\d+)\s+([A-Za-z].+?)\s+([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s*$',
    );
    final match = pattern.firstMatch(line);
    if (match != null) {
      final qty = double.tryParse(match.group(1) ?? '1') ?? 1.0;
      final name = _cleanItemName(match.group(2) ?? '');
      final price = _parseNumber(match.group(3) ?? '');
      if (_isValidItem(name, price)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: qty,
          unitPrice: price / qty,
          totalPrice: price,
        );
      }
    }
    return null;
  }

  /// Single line with inline quantity: "INDOMIE 2x3500    7000"
  ParsedReceiptItem? _tryParseInlineQty(String line) {
    final pattern = RegExp(
      r'^(.+?)\s+(\d+)\s*[xX*@]\s*([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s+([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s*$',
    );
    final match = pattern.firstMatch(line);
    if (match != null) {
      final name = _cleanItemName(match.group(1) ?? '');
      final qty = double.tryParse(match.group(2) ?? '1') ?? 1.0;
      final unitPrice = _parseNumber(match.group(3) ?? '');
      final totalPrice = _parseNumber(match.group(4) ?? '');
      if (_isValidItem(name, totalPrice)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: qty,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
        );
      }
    }
    return null;
  }

  /// Single line with Rp prefix: "INDOMIE GORENG    Rp 3.500"
  ParsedReceiptItem? _tryParseWithRp(String line) {
    final pattern = RegExp(
      r'^(.+?)\s+[Rr][Pp]\.?\s*([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s*$',
    );
    final match = pattern.firstMatch(line);
    if (match != null) {
      final name = _cleanItemName(match.group(1) ?? '');
      final price = _parseNumber(match.group(2) ?? '');
      if (_isValidItem(name, price)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: 1.0,
          unitPrice: price,
          totalPrice: price,
        );
      }
    }
    return null;
  }

  /// Simple "NAME    PRICE" pattern
  ParsedReceiptItem? _tryParseSimple(String line) {
    final pattern = RegExp(
      r'^(.+?)\s{2,}([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)\s*$',
    );
    var match = pattern.firstMatch(line);
    if (match != null) {
      final name = _cleanItemName(match.group(1) ?? '');
      final price = _parseNumber(match.group(2) ?? '');
      if (_isValidItem(name, price)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: 1.0,
          unitPrice: price,
          totalPrice: price,
        );
      }
    }

    // Fallback: single space with formatted number (at least 4 digits or thousands separator)
    final fallbackPattern = RegExp(
      r'^(.+?)\s+([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,})\s*$',
    );
    match = fallbackPattern.firstMatch(line);
    if (match != null) {
      final name = _cleanItemName(match.group(1) ?? '');
      final price = _parseNumber(match.group(2) ?? '');
      if (_isValidItem(name, price)) {
        return ParsedReceiptItem(
          itemName: name,
          quantity: 1.0,
          unitPrice: price,
          totalPrice: price,
        );
      }
    }

    return null;
  }

  bool _isValidItem(String name, double price) {
    if (name.length < 2 || name.length > 50) return false;
    if (price < 100 || price > 100000000) return false;
    if (RegExp(r'^\d+$').hasMatch(name)) return false;
    // Don't treat quantity lines as item names
    if (RegExp(r'^\d+\s*[xX*@]\s*[@]?').hasMatch(name)) return false;
    final upper = name.toUpperCase().trim();
    if (upper == 'TOTAL' ||
        upper == 'SUBTOTAL' ||
        upper == 'SUB TOTAL' ||
        upper == 'GRAND TOTAL' ||
        upper == 'TAGIHAN' ||
        upper == 'BILL' ||
        upper == 'JUMLAH' ||
        upper == 'CASH' ||
        upper == 'TUNAI' ||
        upper == 'KEMBALI' ||
        upper == 'CHANGE') {
      return false;
    }
    return true;
  }

  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s\-*•]+'), '')
        .replaceAll(RegExp(r'[\s\-*•]+$'), '')
        .trim();
  }

  /// Robust grand total extraction that distinguishes monetary totals from item counts / metadata
  double _extractGrandTotal(List<String> lines, List<ParsedReceiptItem> items) {
    final normalizedLines = lines.map(_normalizeNumberSpacing).toList();

    bool isNonMonetaryLine(String upper) {
      return upper.contains('TOTAL ITEM') ||
          upper.contains('TOTAL QTY') ||
          upper.contains('TOTAL PCS') ||
          upper.contains('TOTAL BARIS') ||
          upper.contains('ITEM :') ||
          upper.contains('QTY :') ||
          upper.contains('PAX') ||
          upper.contains('POS ') ||
          upper.contains('SHIFT') ||
          upper.contains('JAM ') ||
          upper.contains('KEMBALI') ||
          upper.contains('CHANGE') ||
          upper.contains('TUNAI') ||
          upper.contains('CASH') ||
          upper.contains('PEMBULATAN') ||
          upper.contains('ROUNDING');
    }

    // Tier 1: Highest confidence explicit grand total keywords
    final tier1Keywords = [
      'GRAND TOTAL',
      'TOTAL BAYAR',
      'TOTAL AKHIR',
      'TOTAL PEMBAYARAN',
      'TOTAL TRANSAKSI',
      'TOTAL TAGIHAN',
    ];

    for (final kw in tier1Keywords) {
      for (final line in normalizedLines.reversed) {
        final upper = line.toUpperCase();
        if (upper.contains(kw) && !isNonMonetaryLine(upper)) {
          final amount = _extractAmountFromLine(line);
          if (amount != null && amount >= 500) {
            return amount;
          }
        }
      }
    }

    // Tier 2: Secondary total keywords
    final tier2Keywords = [
      'TOTAL BELANJA',
      'TOTAL HARGA',
      'JUMLAH TOTAL',
      'AMOUNT DUE',
    ];

    for (final kw in tier2Keywords) {
      for (final line in normalizedLines.reversed) {
        final upper = line.toUpperCase();
        if (upper.contains(kw) && !isNonMonetaryLine(upper)) {
          final amount = _extractAmountFromLine(line);
          if (amount != null && amount >= 500) {
            return amount;
          }
        }
      }
    }

    // Tier 3: General "TOTAL", "BILL", "TAGIHAN" (skipping subtotal, tax, and item count lines)
    final tier3Keywords = ['TOTAL', 'BILL', 'TAGIHAN', 'JUMLAH'];

    for (final kw in tier3Keywords) {
      for (final line in normalizedLines.reversed) {
        final upper = line.toUpperCase();
        if (_subtotalKeywords.any((k) => upper.contains(k)) ||
            _taxKeywords.any((k) => upper.contains(k)) ||
            _discountKeywords.any((k) => upper.contains(k)) ||
            isNonMonetaryLine(upper)) {
          continue;
        }

        if (upper.contains(kw)) {
          final amount = _extractAmountFromLine(line);
          // In Indonesian receipts, grand total is at least 1,000 Rupiah (prevents grabbing 6 or 45)
          if (amount != null && amount >= 1000) {
            return amount;
          }
        }
      }
    }

    // Tier 4: Look for Rp-prefixed amount near bottom
    for (final line in normalizedLines.reversed.take(8)) {
      final upper = line.toUpperCase();
      if (upper.contains('RP') && !isNonMonetaryLine(upper)) {
        final amount = _extractAmountFromLine(line);
        if (amount != null && amount >= 1000) return amount;
      }
    }

    // Tier 5: Fallback based on items sum
    if (items.isNotEmpty) {
      final itemsSum = items.fold(0.0, (s, i) => s + i.totalPrice);
      if (itemsSum > 0) {
        final closest = _findClosestTotal(normalizedLines, itemsSum);
        if (closest != null) return closest;
        return itemsSum;
      }
    }

    return 0.0;
  }

  /// Search for a grand total amount in lines that is close to or greater than items sum
  double? _findClosestTotal(List<String> lines, double itemsSum) {
    final candidateAmounts = <double>[];
    for (final line in lines.reversed.take(12)) {
      final upper = line.toUpperCase();
      // Skip cash lines or change lines
      if (upper.contains('CASH') ||
          upper.contains('TUNAI') ||
          upper.contains('KEMBALI') ||
          upper.contains('CHANGE') ||
          upper.contains('PEMBULATAN')) {
        continue;
      }
      final amount = _extractAmountFromLine(line);
      if (amount != null && amount >= itemsSum * 0.9 && amount <= itemsSum * 2.0) {
        candidateAmounts.add(amount);
      }
    }

    if (candidateAmounts.isNotEmpty) {
      // Return the amount closest to itemsSum (or slightly higher due to tax)
      candidateAmounts.sort();
      // Prefer amount >= itemsSum
      final higher = candidateAmounts.where((a) => a >= itemsSum).toList();
      if (higher.isNotEmpty) return higher.first;
      return candidateAmounts.last;
    }
    return null;
  }

  double? _extractSubtotal(List<String> lines) {
    for (final keyword in _subtotalKeywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _extractAmountFromLine(_normalizeNumberSpacing(line));
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    return null;
  }

  double _extractTax(List<String> lines) {
    for (final keyword in _taxKeywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _extractAmountFromLine(_normalizeNumberSpacing(line));
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    return 0.0;
  }

  double _extractDiscount(List<String> lines) {
    for (final keyword in _discountKeywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _extractAmountFromLine(_normalizeNumberSpacing(line));
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    return 0.0;
  }

  double? _extractAmountFromLine(String line) {
    final normalized = _normalizeNumberSpacing(line);

    // 1. Check for Rp prefix
    final rpRegex = RegExp(
      r'[Rr][Pp]\.?\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+)',
    );
    final rpMatch = rpRegex.firstMatch(normalized);
    if (rpMatch != null) {
      final parsed = _parseNumber(rpMatch.group(1)!);
      if (parsed > 0) return parsed;
    }

    // 2. Look for formatted numbers (thousands separator)
    final formattedRegex = RegExp(
      r'([0-9]{1,3}(?:[.,][0-9]{3})+(?:[.,][0-9]{1,2})?|[0-9]{4,})',
    );
    final matches = formattedRegex.allMatches(normalized).toList();
    if (matches.isNotEmpty) {
      return _parseNumber(matches.last.group(0)!);
    }

    // 3. Fallback for unformatted numbers
    final simpleRegex = RegExp(r'([0-9]+)');
    final simpleMatches = simpleRegex.allMatches(normalized).toList();
    if (simpleMatches.isNotEmpty) {
      return _parseNumber(simpleMatches.last.group(0)!);
    }

    return null;
  }

  /// Parse Indonesian-format number string to double
  double _parseNumber(String str) {
    String clean = str
        .replaceAll(RegExp(r'[Rr][Pp]\.?'), '')
        .replaceAll('IDR', '')
        .replaceAll(' ', '')
        .trim();

    if (clean.isEmpty) return 0.0;

    try {
      // Case 1: Contains both . and ,
      if (clean.contains('.') && clean.contains(',')) {
        final lastDot = clean.lastIndexOf('.');
        final lastComma = clean.lastIndexOf(',');
        if (lastComma > lastDot) {
          // Format: 15.000,00 (dot=thousands, comma=decimal)
          final afterComma = clean.substring(lastComma + 1);
          if (afterComma.length <= 2) {
            return double.parse(clean.replaceAll('.', '').replaceAll(',', '.'));
          } else {
            return double.parse(clean.replaceAll('.', '').replaceAll(',', ''));
          }
        } else {
          // Format: 15,000.00 (comma=thousands, dot=decimal)
          final afterDot = clean.substring(lastDot + 1);
          if (afterDot.length <= 2) {
            return double.parse(clean.replaceAll(',', ''));
          } else {
            return double.parse(clean.replaceAll(',', '').replaceAll('.', ''));
          }
        }
      }

      // Case 2: Contains dots
      if (clean.contains('.')) {
        final afterLastDot = clean.substring(clean.lastIndexOf('.') + 1);
        if (afterLastDot.length == 3) {
          // Indonesian thousands separator: 15.000 -> 15000
          return double.parse(clean.replaceAll('.', ''));
        } else if (afterLastDot.length <= 2) {
          if (clean.indexOf('.') != clean.lastIndexOf('.')) {
            return double.parse(clean.replaceAll('.', ''));
          }
          final asDecimal = double.parse(clean);
          if (asDecimal < 100) {
            return double.parse(clean.replaceAll('.', ''));
          }
          return asDecimal;
        } else {
          return double.parse(clean.replaceAll('.', ''));
        }
      }

      // Case 3: Contains commas
      if (clean.contains(',')) {
        final afterLastComma = clean.substring(clean.lastIndexOf(',') + 1);
        if (afterLastComma.length == 3) {
          // Indonesian thousands separator: 15,000 -> 15000
          return double.parse(clean.replaceAll(',', ''));
        } else if (afterLastComma.length <= 2) {
          if (clean.indexOf(',') != clean.lastIndexOf(',')) {
            return double.parse(clean.replaceAll(',', ''));
          }
          final asDecimal = double.parse(clean.replaceAll(',', '.'));
          if (asDecimal < 100) {
            return double.parse(clean.replaceAll(',', ''));
          }
          return asDecimal;
        } else {
          return double.parse(clean.replaceAll(',', ''));
        }
      }

      // Case 4: Plain integer
      return double.parse(clean);
    } catch (_) {
      return 0.0;
    }
  }

  DateTime _extractDate(String rawText) {
    final datePatterns = [
      {'format': 'dd/MM/yyyy', 'regex': r'\b(\d{1,2}/\d{1,2}/\d{4})\b'},
      {'format': 'dd-MM-yyyy', 'regex': r'\b(\d{1,2}-\d{1,2}-\d{4})\b'},
      {'format': 'dd.MM.yyyy', 'regex': r'\b(\d{1,2}\.\d{1,2}\.\d{4})\b'},
      {'format': 'yyyy-MM-dd', 'regex': r'\b(\d{4}-\d{1,2}-\d{1,2})\b'},
      {'format': 'yyyy/MM/dd', 'regex': r'\b(\d{4}/\d{1,2}/\d{1,2})\b'},
      {'format': 'dd/MM/yy', 'regex': r'\b(\d{1,2}/\d{1,2}/\d{2})\b'},
      {'format': 'dd-MM-yy', 'regex': r'\b(\d{1,2}-\d{1,2}-\d{2})\b'},
    ];

    for (final pattern in datePatterns) {
      final match = RegExp(pattern['regex']!).firstMatch(rawText);
      if (match != null) {
        final dateStr = match.group(1);
        try {
          final parsed = DateFormat(pattern['format']!).parse(dateStr!);
          if (parsed.isAfter(DateTime(2020)) &&
              parsed.isBefore(DateTime.now().add(const Duration(days: 30)))) {
            return parsed;
          }
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  String _detectPaymentMethod(String rawText) {
    final upper = rawText.toUpperCase();
    if (upper.contains('GOPAY') ||
        upper.contains('OVO') ||
        upper.contains('SHOPEEPAY') ||
        upper.contains('DANA') ||
        upper.contains('QRIS') ||
        upper.contains('LINKAJA')) {
      return 'E_WALLET';
    }
    if (upper.contains('DEBIT') ||
        upper.contains('BCA') ||
        upper.contains('MANDIRI') ||
        upper.contains('BRI') ||
        upper.contains('BNI') ||
        upper.contains('CIMB') ||
        upper.contains('BSI')) {
      return 'BANK';
    }
    if (upper.contains('KREDIT') ||
        upper.contains('CREDIT') ||
        upper.contains('VISA') ||
        upper.contains('MASTERCARD') ||
        upper.contains('JCB') ||
        upper.contains('AMEX')) {
      return 'CREDIT';
    }
    return 'CASH';
  }
}
