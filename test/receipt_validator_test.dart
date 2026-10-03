import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recify/data/models/parsed_receipt_data.dart';
import 'package:recify/domain/ocr/receipt_validator.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });

  group('ReceiptValidator', () {
    ParsedReceiptData buildReceipt({
      List<ParsedReceiptItem> items = const [],
      double tax = 0,
      double discount = 0,
      double grandTotal = 0,
    }) {
      return ParsedReceiptData(
        merchantName: 'Test Store',
        transactionDate: DateTime.now(),
        items: items,
        tax: tax,
        discount: discount,
        grandTotal: grandTotal,
      );
    }

    final item = ParsedReceiptItem(
      itemName: 'Mie Gacoan',
      quantity: 2,
      unitPrice: 10455,
      totalPrice: 20910,
    );

    test('valid when grandTotal matches items + tax - discount within tolerance', () {
      // 20910 + 8864 - 0 = 29774 (exact)
      final receipt = buildReceipt(
        items: [item],
        tax: 8864,
        grandTotal: 29774,
      );

      final result = ReceiptValidator.validate(receipt);
      expect(result.status, 'valid');
      expect(result.isValid, isTrue);
      expect(result.needsReview, isFalse);
      expect(result.difference, 0.0);
    });

    test('valid within Rp 500 tolerance (kasir rounding)', () {
      // Expected 29774, actual 29750 → diff 24 (Mie Gacoan real rounding)
      final receipt = buildReceipt(
        items: [item],
        tax: 8864,
        grandTotal: 29750,
      );

      final result = ReceiptValidator.validate(receipt);
      expect(result.status, 'valid');
      expect(result.expectedGrandTotal, closeTo(29774.0, 0.01));
    });

    test('warning when difference is between Rp 500 and Rp 5000', () {
      // Expected 20910, actual 17000 → diff 3910 (service charge not captured?)
      final receipt = buildReceipt(
        items: [item],
        grandTotal: 17000,
      );

      final result = ReceiptValidator.validate(receipt);
      expect(result.status, 'warning');
      expect(result.isValid, isFalse);
      expect(result.needsReview, isFalse);
    });

    test('needs_review when difference is large', () {
      // Expected 20910, actual 10000 → diff 10910 (wrong total parsed)
      final receipt = buildReceipt(
        items: [item],
        grandTotal: 10000,
      );

      final result = ReceiptValidator.validate(receipt);
      expect(result.status, 'needs_review');
      expect(result.needsReview, isTrue);
      expect(result.isValid, isFalse);
    });

    test('discount reduces expected total', () {
      // 20910 - 11700 = 9210 (voucher discount case)
      final receipt = buildReceipt(
        items: [item],
        discount: 11700,
        grandTotal: 9210,
      );

      final result = ReceiptValidator.validate(receipt);
      expect(result.status, 'valid');
    });

    test('warning when no items and no total detected', () => expect(
        ReceiptValidator.validate(buildReceipt()).status, 'warning'));

    test('isValid quick boolean helper works', () {
      expect(
          ReceiptValidator.isValid(buildReceipt(
            items: [item],
            grandTotal: 20910,
          )),
          isTrue);
      expect(
          ReceiptValidator.isValid(buildReceipt(
            items: [item],
            grandTotal: 1,
          )),
          isFalse);
    });
  });

  group('ParsedReceiptData.fromGeminiJson', () {
    test('parses full valid Gemini response', () {
      final data = ParsedReceiptData.fromGeminiJson({
        'merchant': 'Indomaret',
        'date': '2025-01-12',
        'category': 'cat_groceries',
        'payment_method': 'CASH',
        'items': [
          {'name': 'Aqua 600ml', 'qty': 2, 'price': 8000},
          {'name': 'Piattos', 'qty': 1, 'price': 12500},
        ],
        'subtotal': 20500,
        'tax': 0,
        'discount': 11700,
        'grand_total': 8800,
      });

      expect(data.merchantName, 'Indomaret');
      expect(data.suggestedCategory, 'cat_groceries');
      expect(data.paymentMethodDetected, 'CASH');
      expect(data.transactionDate.year, 2025);
      expect(data.transactionDate.month, 1);
      expect(data.transactionDate.day, 12);
      expect(data.currency, 'IDR');
      expect(data.parserSource, 'gemini');
      expect(data.items.length, 2);
      expect(data.items[0].itemName, 'Aqua 600ml');
      expect(data.items[0].quantity, 2.0);
      expect(data.items[0].totalPrice, 8000.0);
      // unitPrice must be price / qty = 4000
      expect(data.items[0].unitPrice, 4000.0);
      expect(data.subtotal, 20500.0);
      expect(data.tax, 0.0);
      expect(data.discount, 11700.0);
      expect(data.grandTotal, 8800.0);
    });

    test('handles null/missing fields with defaults', () {
      final data = ParsedReceiptData.fromGeminiJson({});

      expect(data.merchantName, '');
      expect(data.suggestedCategory, 'cat_groceries');
      expect(data.paymentMethodDetected, 'CASH');
      expect(data.items, isEmpty);
      expect(data.parserSource, 'gemini');
    });

    test('filters items with empty name or zero price', () {
      final data = ParsedReceiptData.fromGeminiJson({
        'items': [
          {'name': '', 'qty': 1, 'price': 5000},
          {'name': 'Valid Item', 'qty': 1, 'price': 10000},
          {'name': 'Zero Price', 'qty': 1, 'price': 0},
          'not-a-map',
        ],
      });

      expect(data.items.length, 1);
      expect(data.items[0].itemName, 'Valid Item');
    });

    test('falls back to items sum when subtotal missing', () {
      final data = ParsedReceiptData.fromGeminiJson({
        'items': [
          {'name': 'A', 'qty': 1, 'price': 15000},
          {'name': 'B', 'qty': 2, 'price': 30000},
        ],
        'grand_total': 45000,
      });

      expect(data.subtotal, 45000.0);
    });

    test('accepts readable old dates; rejects unreasonable ones', () {
      // Nota lama terbaca & valid harus DITERIMA (umur diatur Task 2:
      // dialog >7 hari). Batas bawah sanity = 1990.
      final old = ParsedReceiptData.fromGeminiJson({
        'date': '2015-05-01',
      });
      expect(old.dateFallback, isFalse);
      expect(old.transactionDate.year, 2015);

      // Di bawah batas 1990 → fallback ke now.
      final ancient = ParsedReceiptData.fromGeminiJson({
        'date': '1985-05-01',
      });
      expect(ancient.dateFallback, isTrue);
      expect(ancient.transactionDate.year, DateTime.now().year);

      // Far future (>30 hari) tetap dianggap tak wajar → fallback.
      final future = ParsedReceiptData.fromGeminiJson({
        'date': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      });
      expect(future.dateFallback, isTrue);
      expect(future.transactionDate.year, DateTime.now().year);
    });

    test('accepts non-ISO formats the model often returns', () {
      final monthName = ParsedReceiptData.fromGeminiJson({
        'date': 'September 15, 2024',
      });
      expect(monthName.dateFallback, isFalse);
      expect(monthName.transactionDate.year, 2024);
      expect(monthName.transactionDate.month, 9);

      final usOrder = ParsedReceiptData.fromGeminiJson({
        'date': '09/15/2024',
      });
      expect(usOrder.dateFallback, isFalse);
      expect(usOrder.transactionDate.month, 9);
      expect(usOrder.transactionDate.day, 15);

      final slashId = ParsedReceiptData.fromGeminiJson({
        'date': '15/09/2024',
      });
      expect(slashId.dateFallback, isFalse);
      expect(slashId.transactionDate.day, 15);
    });

    test('rantai date_raw: date null tapi verbatim ada → diterima', () {
      final viaRaw = ParsedReceiptData.fromGeminiJson({
        'date': null,
        'date_raw': '3 Mei 2024',
      });
      expect(viaRaw.dateFallback, isFalse);
      expect(viaRaw.transactionDate.month, 5);
      expect(viaRaw.transactionDate.day, 3);

      // date ISO tetap prioritas di atas date_raw bila dua-duanya ada.
      final both = ParsedReceiptData.fromGeminiJson({
        'date': '2024-11-24',
        'date_raw': '3 Mei 2024',
      });
      expect(both.dateFallback, isFalse);
      expect(both.transactionDate.month, 11);
    });

    test('rescues date from raw OCR text when model returns null', () {
      final rescued = ParsedReceiptData.fromGeminiJson(
        {'date': null},
        rawText: 'ARTISAN CAFE\nTANGGAL: 24/11/2024\nTOTAL 50.000',
      );
      expect(rescued.dateFallback, isFalse);
      expect(rescued.transactionDate.year, 2024);
      expect(rescued.transactionDate.month, 11);

      final nothing = ParsedReceiptData.fromGeminiJson(
        {'date': null},
        rawText: 'TOTAL 50000\nTERIMA KASIH',
      );
      expect(nothing.dateFallback, isTrue);
    });
  });
}
