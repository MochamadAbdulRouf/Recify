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
      // Fixture derived from real ML Kit OCR output (with column gap preserved as multi-space).
      // Verifies: 6 items detected, qty 3 not dropped, plain "Total" keyword recognized, tax/service not leaked as items.
      const ichibanOcrText = '''
Aug 19, 2024 6:32:54 PM    Server: RIVAN MAULANA
TBL 11    PAX: 2
- - - - - - - - - - - - - - - - - - -
1  Beef Teriyaki Ramen                       42,000
3  Sapporo Garlic Sesame Rame (DITA         39,000
1  Katsu Roll                                35,000
1  Salmon sakura                             35,000
1  Spicy Creamy Namazu Roll                  35,000
1  Black Current 1L                          37,000
- - - - - - - - - - - - - - - - - - -
Total Item : 6               Total Qty : 6
Subtotal                              223,000
Service Charge                         11,150
Tax Resto 10%                          23,415
Total                                257,565
- - - - - - - - - - - - - - - - - - -
Printed Aug 19, 2024 7:08:29 PM
''';

      final result = parser.parse(ichibanOcrText);

      // Verify Category (must be cat_food, NOT cat_groceries)
      expect(result.suggestedCategory, 'cat_food');

      // Verify Grand Total (must be 257565, NOT 6)
      expect(result.grandTotal, 257565.0);

      // Verify Subtotal
      expect(result.subtotal, 223000.0);

      // Verify Merchant must NOT be a line of items.
      expect(result.merchantName, isNot(contains('42,000')));
      expect(result.merchantName, isNot(contains('Beef Teriyaki')));

      // Verify Items count (must be 6 items)
      expect(result.items.length, 6);

      expect(result.items[0].itemName, 'Beef Teriyaki Ramen');
      expect(result.items[0].quantity, 1.0);
      expect(result.items[0].totalPrice, 42000.0);

      expect(result.items[1].itemName, contains('Sapporo Garlic Sesame Rame'));
      expect(result.items[1].quantity, 3.0,
          reason: 'qty=3 (multi-digit) must survive the parser');
      expect(result.items[1].totalPrice, 39000.0);

      // No item should leak tax/service/subtotal as a row.
      for (final item in result.items) {
        expect(item.itemName.toUpperCase(), isNot(contains('SERVICE')));
        expect(item.itemName.toUpperCase(), isNot(contains('TAX')));
        expect(item.itemName.toUpperCase(), isNot(contains('SUBTOTAL')));
      }

      expect(result.items[2].itemName, 'Katsu Roll');
      expect(result.items[2].totalPrice, 35000.0);

      expect(result.items[3].itemName, 'Salmon sakura');
      expect(result.items[3].totalPrice, 35000.0);

      expect(result.items[4].itemName, 'Spicy Creamy Namazu Roll');
      expect(result.items[4].totalPrice, 35000.0);

      expect(result.items[5].itemName, 'Black Current 1L');
      expect(result.items[5].totalPrice, 37000.0);
    });

    test('Handles OCR misread of "Total" as "Totol" - must NOT parse as item (480k bug)', () {
      // Reproduces the exact bug: OCR misreads "Total" → "Totol" 
      // causing it to slip through _isSkipItemLine and be parsed as an item.
      // Items sum then becomes subtotal + real_total = 480,565 instead of 257,565.
      const ocrWithMisread = '''
Aug 19, 2024 6:32:54 PM    Server: RIVAN MAULANA
TBL 11    PAX: 2
- - - - - - - - - - - - - - - - - - -
1  Beef Teriyaki Ramen                       42,000
1  Sapporo Garlic Sesame Rame (DITA)         39,000
1  Katsu Roll                                35,000
1  Salmon sakura                             35,000
1  Spicy Creamy Namazu Roll                  35,000
1  Black Current 1L                          37,000
- - - - - - - - - - - - - - - - - - -
Total Item : 6               Total Qty : 6
Subtotal                              223,000
Service Charge                         11,150
Tax Resto 10%                          23,415
Totol                                257,565
- - - - - - - - - - - - - - - - - - -
Printed Aug 19, 2024 7:08:29 PM
''';

      final result = parser.parse(ocrWithMisread);

      // Grand total must be 257,565 NOT 480,565 (which would be subtotal + total)
      expect(result.grandTotal, closeTo(257565.0, 1.0),
          reason: 'Total must be ~257,565 even when OCR misreads "Total" as "Totol"');

      // Must have exactly 6 items, NOT 7
      expect(result.items.length, 6,
          reason: '"Totol 257,565" must NOT be parsed as an item');

      // Items sum must be 223,000
      final itemsSum = result.items.fold(0.0, (s, i) => s + i.totalPrice);
      expect(itemsSum, 223000.0);
    });

    test('Tax extraction sums multiple tax charges (Service Charge + Tax Resto)', () {
      const receiptWithMultipleTaxes = '''
Kasir : POS 1
=============================
NASI GORENG
 1 X @ 25,000    25,000
ES TEH MANIS
 1 X @ 8,000    8,000
-----------------------------
Subtotal                              33,000
Service Charge 5%                      1,650
Tax Resto 10%                          3,300
Grand Total                           37,950
Cash                                  50,000
''';

      final result = parser.parse(receiptWithMultipleTaxes);

      // Tax must be Service Charge + Tax Resto = 1,650 + 3,300 = 4,950
      expect(result.tax, 4950.0,
          reason: 'Tax must sum ALL tax-related charges');

      expect(result.grandTotal, 37950.0);
      expect(result.items.length, 2);
    });

    test('Handles OCR misread of "Totel" variant', () {
      const ocrWithTotel = '''
Kasir : POS 1
=============================
KOPI LATTE                            25,000
CROISSANT                             18,000
-----------------------------
Subtotal                              43,000
PPN 11%                                4,730
Totel                                 47,730
''';

      final result = parser.parse(ocrWithTotel);

      // "Totel" must not become an item
      expect(result.items.length, 2);
      expect(result.items[0].itemName, 'KOPI LATTE');
      expect(result.items[1].itemName, 'CROISSANT');
      
      final itemsSum = result.items.fold(0.0, (s, i) => s + i.totalPrice);
      expect(itemsSum, 43000.0);
    });

    test('Handles OCR splitting "Total" keyword and amount on separate lines (223k bug)', () {
      // Reproduces the real-world scenario where ML Kit OCR puts "Total" and "257,565"
      // on separate lines, causing the parser to fall back to items sum (223,000)
      const ocrSplitTotal = '''
Aug 19, 2024 6:32:54 PM    Server: RIVAN MAULANA
TBL 11    PAX: 2
- - - - - - - - - - - - - - - - - - -
1  Beef Teriyaki Ramen                       42,000
1  Sapporo Garlic Sesame Rame (DITA)         39,000
1  Katsu Roll                                35,000
1  Salmon sakura                             35,000
1  Spicy Creamy Namazu Roll                  35,000
1  Black Current 1L                          37,000
- - - - - - - - - - - - - - - - - - -
Total Item : 6               Total Qty : 6
Subtotal                              223,000
Service Charge                         11,150
Tax Resto 10%                          23,415
Total
257,565
- - - - - - - - - - - - - - - - - - -
Printed Aug 19, 2024 7:08:29 PM
''';

      final result = parser.parse(ocrSplitTotal);

      // Grand total must be 257,565 NOT 223,000 (items sum / subtotal)
      expect(result.grandTotal, closeTo(257565.0, 1.0),
          reason: 'Must find 257,565 from adjacent line when Total keyword has no amount');

      expect(result.items.length, 6);

      final itemsSum = result.items.fold(0.0, (s, i) => s + i.totalPrice);
      expect(itemsSum, 223000.0);
    });

    test('Handles receipt where Total and amount are on same line (normal case)', () {
      // Verify the normal case still works after all the fixes
      const normalReceipt = '''
TBL 11    PAX: 2
- - - - - - - - - - - - - - - - - - -
1  Beef Teriyaki Ramen                       42,000
1  Katsu Roll                                35,000
- - - - - - - - - - - - - - - - - - -
Subtotal                               77,000
Tax Resto 10%                           7,700
Total                                  84,700
''';

      final result = parser.parse(normalReceipt);

      expect(result.grandTotal, 84700.0);
      expect(result.items.length, 2);
    });

    test('Parses Indomaret receipt with address, vouchers, and HARGA JUAL', () {
      const indomaretReceipt = '''
INDOMARET
JL RAYA BOJONGSOANG
KEC BOJONGSOANG, KAB BANDUNG 40.287
03.08.24-14:43/3.0.16/FGFF 1436145/RISMA/02
PIATTOS SAPI PNG 68G   2 11200   22,400
MR.BREAD TAWAR KUPAS   1 16500   16,500
INDOMI AYAM BWNG 69G   6 3100    18,600
GERY MLKS SLT COK100   1 8800     8,800
   VC GARUDAFOOD PU :    (1,900)
SLAI O'LAI STRW 128G   1 8200     8,200
IDM KTG PLSTK 1W SDG   1 200        200
VC PIATTOS SAPI PNG 68G/PT URC : (8,200)
VC INDOMIE KUAH/INDOFOOD CBP :   (1,600)
---------------------------------------
HARGA JUAL :                      63,000
TOTAL :                           63,000
TUNAI :                          100,000
KEMBALIAN :                       37,000
''';

      final result = parser.parse(indomaretReceipt);

      // Total must be 63,000, NOT 173,690
      expect(result.grandTotal, 63000.0,
          reason: 'Indomaret total must be 63,000');

      // Merchant should be INDOMARET
      expect(result.merchantName.toUpperCase(), contains('INDOMARET'));

      // Items should have the 6 grocery items (NO address, NO vouchers, NO harga jual)
      expect(result.items.length, 6,
          reason: 'Address, vouchers, and HARGA JUAL must not be items');

      // Check item details
      expect(result.items.any((i) => i.itemName.contains('PIATTOS')), isTrue);
      expect(result.items.any((i) => i.itemName.contains('BOJONGSOANG')), isFalse);
      expect(result.items.any((i) => i.itemName.contains('HARGA JUAL')), isFalse);
      expect(result.items.any((i) => i.itemName.contains('GARUDAFOOD')), isFalse);

      // Voucher discount should be summed: 1900 + 8200 + 1600 = 11700
      expect(result.discount, 11700.0);
    });

    test('Parses Mie Gacoan receipt with P81 typo, rounding, and 11 Items count', () {
      const gacoanReceipt = '''
MIE GACOAN
Date : 12-01-2025 15:37
Info : Dilla putri - 25
Purpose : 01.DINE IN
Cashier : NAYYA
2   MIE GACOAN        20.910
1   MIE GACOAN LV 3    10.455
1   MIE HOMPIMPA LV 1  10.455
3   AIR MINERAL BOTOL  13.636
1   TEA                 4.546
1   LUMPIA UDANG        9.546
1   SIOMAY AYAM         9.546
1   UDANG KEJU          9.546
---------------------------------
11 Items
Subtotal :             88.642
P81 :                   8.864
Total :                97.506
Rounding :                 -6
Grand Total :          97.500
Cash :                100.000
Change :                2.500
''';

      final result = parser.parse(gacoanReceipt);

      // Total must be 97,500, NOT 69,413
      expect(result.grandTotal, closeTo(97500.0, 1.0),
          reason: 'Mie Gacoan Grand Total must be 97,500');

      // P81 (PB1) must be parsed as tax, NOT an item
      expect(result.tax, closeTo(8864.0, 1.0),
          reason: 'P81 must be recognized as PB1 tax');

      // Must have 8 menu items (NO 11 Items, NO P81, NO Rounding)
      expect(result.items.length, 8,
          reason: 'P81 and Rounding must not be items');

      expect(result.items.any((i) => i.itemName.contains('P81')), isFalse);
      expect(result.items.any((i) => i.itemName.contains('Rounding')), isFalse);
    });
  });
}
