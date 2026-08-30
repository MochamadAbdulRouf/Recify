import 'package:intl/intl.dart';
import '../../data/models/parsed_receipt_data.dart';

class IndonesianReceiptParser {
  static const List<Map<String, String>> _merchantKeywordMap = [
    {'keyword': 'INDOMARET', 'category': 'cat_groceries'},
    {'keyword': 'ALFAMART', 'category': 'cat_groceries'},
    {'keyword': 'ALFAMIDI', 'category': 'cat_groceries'},
    {'keyword': 'SUPERINDO', 'category': 'cat_groceries'},
    {'keyword': 'HYPERMART', 'category': 'cat_groceries'},
    {'keyword': 'TRANSMART', 'category': 'cat_groceries'},
    {'keyword': 'HERO', 'category': 'cat_groceries'},
    {'keyword': 'FARMERS MARKET', 'category': 'cat_groceries'},
    {'keyword': 'PERTAMINA', 'category': 'cat_transport'},
    {'keyword': 'SPBU', 'category': 'cat_transport'},
    {'keyword': 'SHELL', 'category': 'cat_transport'},
    {'keyword': 'BP', 'category': 'cat_transport'},
    {'keyword': 'STARBUCKS', 'category': 'cat_food'},
    {'keyword': 'KFC', 'category': 'cat_food'},
    {'keyword': 'MCDONALD', 'category': 'cat_food'},
    {'keyword': 'MIE GACOAN', 'category': 'cat_food'},
    {'keyword': 'SOLARIA', 'category': 'cat_food'},
    {'keyword': 'HOKBEN', 'category': 'cat_food'},
    {'keyword': 'PIZZA HUT', 'category': 'cat_food'},
    {'keyword': 'JANJI JIWA', 'category': 'cat_food'},
    {'keyword': 'KOPI KENANGAN', 'category': 'cat_food'},
    {'keyword': 'WARKOP', 'category': 'cat_food'},
    {'keyword': 'APOTEK', 'category': 'cat_health'},
    {'keyword': 'KIMIA FARMA', 'category': 'cat_health'},
    {'keyword': 'CENTURY', 'category': 'cat_health'},
    {'keyword': 'GUARDIAN', 'category': 'cat_health'},
    {'keyword': 'UNIQLO', 'category': 'cat_shopping'},
    {'keyword': 'ZARA', 'category': 'cat_shopping'},
    {'keyword': 'MINISO', 'category': 'cat_shopping'},
    {'keyword': 'GRAMEDIA', 'category': 'cat_shopping'},
  ];

  static const List<String> _totalKeywords = [
    'GRAND TOTAL',
    'TOTAL BAYAR',
    'TOTAL AKHIR',
    'TOTAL TRANSAKSI',
    'HARGA JUAL',
    'JUMLAH TOTAL',
    'TOTAL',
    'JUMLAH',
    'TAGIHAN',
    'NETTO',
    'NET TOTAL',
  ];

  static const List<String> _subtotalKeywords = ['SUB TOTAL', 'SUBTOTAL', 'TOTAL HARGA', 'TOTAL SEBELUM PAJAK'];
  static const List<String> _taxKeywords = ['PAJAK', 'PPN', 'PB1', 'TAX', 'PPN 11%', 'PPN 10%'];
  static const List<String> _discountKeywords = ['DISKON', 'DISCOUNT', 'HEMAT', 'POTONGAN', 'PROMO'];

  ParsedReceiptData parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String merchantName = _extractMerchantName(lines);
    String suggestedCategory = _detectCategoryFromMerchant(merchantName);
    final transactionDate = _extractDate(rawText);

    final total = _extractGrandTotal(lines);
    final subtotal = _extractSubtotal(lines) ?? total;
    final tax = _extractTax(lines);
    final discount = _extractDiscount(lines);
    final items = _extractItems(lines);

    if (items.isNotEmpty && suggestedCategory == 'cat_groceries') {
      final refined = _refineCategoryFromItems(items);
      if (refined != null) suggestedCategory = refined;
    }

    if (merchantName.isEmpty && lines.isNotEmpty) {
      merchantName = lines.firstWhere(
        (l) => l.length >= 3 && l.length <= 35 && !RegExp(r'[0-9]{5,}').hasMatch(l),
        orElse: () => 'Nota Belanja',
      );
    }

    return ParsedReceiptData(
      merchantName: merchantName,
      suggestedCategory: suggestedCategory,
      transactionDate: transactionDate,
      currency: 'IDR',
      paymentMethodDetected: _detectPaymentMethod(rawText),
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: total,
      rawText: rawText,
      localImageTempPath: imagePath,
    );
  }

  String _extractMerchantName(List<String> lines) {
    for (final line in lines.take(6)) {
      final upper = line.toUpperCase();
      for (final entry in _merchantKeywordMap) {
        if (upper.contains(entry['keyword']!)) {
          return line.trim();
        }
      }
    }
    for (final line in lines.take(3)) {
      if (line.length >= 4 && line.length <= 30 && !RegExp(r'\d').hasMatch(line)) {
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
    if (text.contains('KOPI') || text.contains('NASI') || text.contains('AYAM') || text.contains('BURGER') || text.contains('MIE')) {
      return 'cat_food';
    }
    if (text.contains('BENSIN') || text.contains('PERTALITE') || text.contains('SOLAR') || text.contains('DEX')) {
      return 'cat_transport';
    }
    if (text.contains('OBAT') || text.contains('PARACETAMOL') || text.contains('VITAMIN')) {
      return 'cat_health';
    }
    return null;
  }

  double _extractGrandTotal(List<String> lines) {
    for (final keyword in _totalKeywords) {
      for (final line in lines.reversed) {
        final upper = line.toUpperCase();
        if (upper.contains(keyword)) {
          final amount = _extractAmountFromLine(line);
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    final allAmounts = lines.map((l) => _extractAmountFromLine(l)).whereType<double>().toList();
    if (allAmounts.isNotEmpty) {
      allAmounts.sort();
      return allAmounts.last;
    }
    return 0.0;
  }

  double? _extractSubtotal(List<String> lines) {
    for (final keyword in _subtotalKeywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _extractAmountFromLine(line);
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
          final amount = _extractAmountFromLine(line);
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
          final amount = _extractAmountFromLine(line);
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    return 0.0;
  }

  List<ParsedReceiptItem> _extractItems(List<String> lines) {
    final result = <ParsedReceiptItem>[];
    final itemPattern = RegExp(r'^(.*?)\s+([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?)$');

    for (final line in lines) {
      final upper = line.toUpperCase();
      if (_totalKeywords.any((k) => upper.contains(k)) ||
          _subtotalKeywords.any((k) => upper.contains(k)) ||
          _taxKeywords.any((k) => upper.contains(k)) ||
          _discountKeywords.any((k) => upper.contains(k)) ||
          upper.contains('TUNAI') ||
          upper.contains('KEMBALI') ||
          upper.contains('CASH')) {
        continue;
      }

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final priceStr = match.group(2) ?? '';
        final price = _parseNumber(priceStr);

        if (name.length >= 3 && name.length <= 40 && price > 500 && price < 50000000) {
          result.add(
            ParsedReceiptItem(
              itemName: name,
              quantity: 1.0,
              unitPrice: price,
              totalPrice: price,
            ),
          );
        }
      }
    }
    return result;
  }

  double? _extractAmountFromLine(String line) {
    final regex = RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]+)');
    final matches = regex.allMatches(line).toList();
    if (matches.isEmpty) return null;

    final lastMatch = matches.last.group(0)!;
    return _parseNumber(lastMatch);
  }

  double _parseNumber(String str) {
    final clean = str.replaceAll('Rp', '').replaceAll('rp', '').replaceAll('IDR', '').trim();
    try {
      if (clean.contains('.') && clean.contains(',')) {
        if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
          return double.parse(clean.replaceAll('.', '').replaceAll(',', '.'));
        } else {
          return double.parse(clean.replaceAll(',', ''));
        }
      } else if (clean.contains('.') && clean.length - clean.lastIndexOf('.') == 4) {
        // E.g. 15.000
        return double.parse(clean.replaceAll('.', ''));
      } else if (clean.contains(',') && clean.length - clean.lastIndexOf(',') == 4) {
        return double.parse(clean.replaceAll(',', ''));
      } else {
        return double.parse(clean.replaceAll('.', '').replaceAll(',', ''));
      }
    } catch (_) {
      return 0.0;
    }
  }

  DateTime _extractDate(String rawText) {
    final datePatterns = [
      {'format': 'dd/MM/yyyy', 'regex': r'\b(\d{1,2}/\d{1,2}/\d{4})\b'},
      {'format': 'dd-MM-yyyy', 'regex': r'\b(\d{1,2}-\d{1,2}-\d{4})\b'},
      {'format': 'dd.MM.yyyy', 'regex': r'\b(\d{1,2}\.\d{1,2}\.\d{4})\b'},
      {'format': 'dd/MM/yy', 'regex': r'\b(\d{1,2}/\d{1,2}/\d{2})\b'},
      {'format': 'dd-MM-yy', 'regex': r'\b(\d{1,2}-\d{1,2}-\d{2})\b'},
    ];

    for (final pattern in datePatterns) {
      final match = RegExp(pattern['regex']!).firstMatch(rawText);
      if (match != null) {
        final dateStr = match.group(1);
        try {
          final parsed = DateFormat(pattern['format']!).parse(dateStr!);
          return parsed;
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  String _detectPaymentMethod(String rawText) {
    final upper = rawText.toUpperCase();
    if (upper.contains('GOPAY') || upper.contains('OVO') || upper.contains('SHOPEEPAY') || upper.contains('DANA') || upper.contains('QRIS')) {
      return 'E_WALLET';
    }
    if (upper.contains('DEBIT') || upper.contains('BCA') || upper.contains('MANDIRI') || upper.contains('BRI') || upper.contains('BNI')) {
      return 'BANK';
    }
    if (upper.contains('KREDIT') || upper.contains('CREDIT') || upper.contains('VISA') || upper.contains('MASTERCARD')) {
      return 'CREDIT';
    }
    return 'CASH';
  }
}
