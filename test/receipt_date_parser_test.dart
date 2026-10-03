import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recify/core/utils/receipt_date_parser.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });
  group('parseReceiptDate', () {
    test('format numerik ID (DD/MM) didahulukan', () {
      final d = parseReceiptDate('24/11/2024');
      expect(d, isNotNull);
      expect(d!.day, 24);
      expect(d.month, 11);
      expect(d.year, 2024);

      // Ambigu → tetap DD/MM (konvensi ID).
      final amb = parseReceiptDate('09/10/2024');
      expect(amb!.day, 9);
      expect(amb.month, 10);
    });

    test('format MM/DD AS hanya bila DD/MM tidak valid', () {
      final us = parseReceiptDate('09/15/2024'); // bulan 15 mustahil DD/MM
      expect(us, isNotNull);
      expect(us!.month, 9);
      expect(us.day, 15);
    });

    test('ISO dan nama bulan EN', () {
      expect(parseReceiptDate('2024-11-24')!.year, 2024);
      expect(parseReceiptDate('2024/11/24')!.day, 24);

      final named = parseReceiptDate('15 Sep 2024');
      expect(named, isNotNull);
      expect(named!.month, 9);
      expect(named.day, 15);

      final named2 = parseReceiptDate('September 15, 2024');
      expect(named2, isNotNull);
      expect(named2!.year, 2024);
    });

    test('nama bulan Indonesia (ID locale)', () {
      final mei = parseReceiptDate('3 Mei 2024');
      expect(mei, isNotNull);
      expect(mei!.month, 5);
      expect(mei.day, 3);

      final peb = parseReceiptDate('15 Pebruari 2024');
      expect(peb, isNotNull);
      expect(peb!.month, 2);

      final des = parseReceiptDate('31 Desember 2024');
      expect(des, isNotNull);
      expect(des!.month, 12);

      final bawahKecil = extractReceiptDate('TANGGAL: 24 nov 2024\nTOTAL');
      expect(bawahKecil, isNotNull);
      expect(bawahKecil!.month, 11);

      // Ambigu DD/MM mengalahkan MM/DD meski ada varian ID: 09/10 = 9 Okt.
      final ambId = parseReceiptDate('09/10/2024');
      expect(ambId!.day, 9);
      expect(ambId.month, 10);
    });

    test('nota lama diterima, di luar rentang ditolak', () {
      expect(parseReceiptDate('01/05/2015')!.year, 2015);
      expect(parseReceiptDate('15/09/2019'), isNotNull);

      expect(parseReceiptDate('01/05/1985'), isNull); // < 1990
      expect(
        parseReceiptDate('01/01/2100'),
        isNull,
      ); // jauh ke depan
      expect(parseReceiptDate(''), isNull);
      expect(parseReceiptDate('bukan tanggal'), isNull);
      expect(
        parseReceiptDate(
          '${DateTime.now().add(const Duration(days: 60)).day.toString().padLeft(2, '0')}/01/2099',
        ),
        isNull,
      );
    });
  });
}
