import 'package:flutter_test/flutter_test.dart';
import 'package:recify/domain/ocr/indonesian_receipt_parser.dart';

void main() {
  group('IndonesianReceiptParser Real-World Receipts Test', () {
    final parser = IndonesianReceiptParser();

    test('Parses Mie Gacoan receipt with two-line item format and rounding', () {
      const gacoanOcrText = '''
Jam : 19:04:03
Nama Tamu : B K 24
Kasir : shift 2 pos 1
=============================
MIE GACOAN LV 1
 1 X @ 10,000    10,000
MIE GACOAN LV 2
 1 X @ 10,000    10,000
MIE GACOAN LV 3
 1 X @ 10,000    10,000
UDANG KEJU
 1 X @ 9,099    9,099
UDANG RAMBUTAN
 2 X @ 9,099    18,198
ES GOBAK SODOR
 1 X @ 9,099    9,099
TEA
 1 X @ 4,099    4,099
-----------------------------
Sub Total :    70,495
Pajak 10% :    7,050
Bill :    77,545
Pembulatan :    -45
Grand Total :    77,500
Cash :    100,000
''';

      final result = parser.parse(gacoanOcrText);

      // Verify Category
      expect(result.suggestedCategory, 'cat_food');

      // Verify Grand Total (must be 77500, NOT 500)
      expect(result.grandTotal, 77500.0);

      // Verify Subtotal & Tax
      expect(result.subtotal, 70495.0);
      expect(result.tax, 7050.0);

      // Verify Items (must have 7 real items, NO "1x@10,000" items)
      expect(result.items.length, 7);

      expect(result.items[0].itemName, 'MIE GACOAN LV 1');
      expect(result.items[0].quantity, 1.0);
      expect(result.items[0].totalPrice, 10000.0);

      expect(result.items[1].itemName, 'MIE GACOAN LV 2');
      expect(result.items[1].quantity, 1.0);
      expect(result.items[1].totalPrice, 10000.0);

      expect(result.items[2].itemName, 'MIE GACOAN LV 3');
      expect(result.items[2].quantity, 1.0);
      expect(result.items[2].totalPrice, 10000.0);

      expect(result.items[3].itemName, 'UDANG KEJU');
      expect(result.items[3].quantity, 1.0);
      expect(result.items[3].totalPrice, 9099.0);

      expect(result.items[4].itemName, 'UDANG RAMBUTAN');
      expect(result.items[4].quantity, 2.0);
      expect(result.items[4].unitPrice, 9099.0);
      expect(result.items[4].totalPrice, 18198.0);

      expect(result.items[5].itemName, 'ES GOBAK SODOR');
      expect(result.items[5].quantity, 1.0);
      expect(result.items[5].totalPrice, 9099.0);

      expect(result.items[6].itemName, 'TEA');
      expect(result.items[6].quantity, 1.0);
      expect(result.items[6].totalPrice, 4099.0);

      // Ensure no item name contains "1 x @" or "@"
      for (final item in result.items) {
        expect(item.itemName.contains('@'), isFalse);
      }
    });

    test('Parses Ichiban Sushi receipt with leading quantities and total items', () {
      const ichibanOcrText = '''
Aug 19, 2024 6:32:54 PM    Server: RIVAN MAULANA
TBL 11    PAX: 2
1 Beef Teriyaki Ramen    42,000
1 Sapporo Garlic Sesame Rame (DITA    39,000
1 Katsu Roll    35,000
1 Salmon sakura    35,000
1 Spicy Creamy Namazu Roll    35,000
1 Black Current 1L    37,000
Total Item : 6    Total Qty : 6
Subtotal    223,000
Service Charge    11,150
Tax Resto 10%    23,415
Total    257,565
Printed Aug 19, 2024 7:08:29 PM
''';

      final result = parser.parse(ichibanOcrText);

      // Verify Category (must be cat_food, NOT cat_groceries)
      expect(result.suggestedCategory, 'cat_food');

      // Verify Grand Total (must be 257565, NOT 6)
      expect(result.grandTotal, 257565.0);

      // Verify Subtotal
      expect(result.subtotal, 223000.0);

      // Verify Items count (must be 6 items)
      expect(result.items.length, 6);

      expect(result.items[0].itemName, 'Beef Teriyaki Ramen');
      expect(result.items[0].quantity, 1.0);
      expect(result.items[0].totalPrice, 42000.0);

      expect(result.items[1].itemName, contains('Sapporo Garlic Sesame Rame'));
      expect(result.items[1].totalPrice, 39000.0);

      expect(result.items[2].itemName, 'Katsu Roll');
      expect(result.items[2].totalPrice, 35000.0);

      expect(result.items[3].itemName, 'Salmon sakura');
      expect(result.items[3].totalPrice, 35000.0);

      expect(result.items[4].itemName, 'Spicy Creamy Namazu Roll');
      expect(result.items[4].totalPrice, 35000.0);

      expect(result.items[5].itemName, 'Black Current 1L');
      expect(result.items[5].totalPrice, 37000.0);
    });
  });
}
