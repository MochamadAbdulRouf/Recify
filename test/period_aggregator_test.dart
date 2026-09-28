import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/period_aggregator.dart';
import 'package:recify/data/models/transaction_model.dart';

// Fixed "now": Monday 28 Sep 2026, 10:00.
final _now = DateTime(2026, 9, 28, 10);

TransactionModel _tx(String type, double amount, DateTime date) =>
    TransactionModel(
      id: '${type}_${amount}_${date.millisecondsSinceEpoch}',
      walletId: 'w1',
      type: type,
      amount: amount,
      transactionDate: date.millisecondsSinceEpoch,
      createdAt: date.millisecondsSinceEpoch,
    );

List<PeriodBucket> _agg(
  List<TransactionModel> txs,
  String type,
  PeriodGranularity g, {
  DateTime? now,
}) =>
    PeriodAggregator.aggregate(
      transactions: txs,
      type: type,
      granularity: g,
      now: now ?? _now,
    );

void main() {
  group('daily', () {
    test('3 hari terakhir, hari ini paling kanan, terakhir isCurrent', () {
      final txs = [
        _tx('EXPENSE', 10000, DateTime(2026, 9, 28, 9)),
        _tx('EXPENSE', 5000, DateTime(2026, 9, 27, 15)),
        _tx('EXPENSE', 2500, DateTime(2026, 9, 26, 8)),
        _tx('EXPENSE', 999999, DateTime(2026, 9, 25, 12)), // di luar jendela
      ];

      final buckets = _agg(txs, 'EXPENSE', PeriodGranularity.daily);

      expect(buckets.length, 3);
      expect(buckets.map((b) => b.total).toList(), [2500, 5000, 10000]);
      expect(buckets.map((b) => b.count).toList(), [1, 1, 1]);
      expect(buckets.last.isCurrent, isTrue);
      expect(buckets.first.isCurrent, isFalse);
      expect(buckets.last.start.day, 28);
    });

    test('tanpa transaksi => 3 bucket nol, bukan error', () {
      final buckets = _agg([], 'EXPENSE', PeriodGranularity.daily);
      expect(buckets.length, 3);
      expect(buckets.every((b) => b.total == 0 && b.count == 0), isTrue);
      expect(buckets.last.isCurrent, isTrue);
    });
  });

  group('weekly', () {
    test('6 minggu ISO, Senin 00:00 inklusif, Minggu masuk minggu sama', () {
      final txs = [
        _tx('EXPENSE', 7000, DateTime(2026, 9, 28, 9)), // Senin minggu ini
        _tx('EXPENSE', 3000, DateTime(2026, 9, 27, 20)), // Minggu minggu lalu
        _tx('EXPENSE', 1000, DateTime(2026, 9, 21, 0)), // Senin 00:00 pas
      ];

      final buckets = _agg(txs, 'EXPENSE', PeriodGranularity.weekly);

      expect(buckets.length, 6);
      expect(buckets[5].total, 7000); // minggu berjalan
      expect(buckets[4].total, 4000); // 27 Sep + 21 Sep satu minggu
      expect(buckets[4].count, 2);
      expect(buckets.last.isCurrent, isTrue);
      expect(buckets.first.isCurrent, isFalse);
      expect(buckets.first.start.weekday, DateTime.monday);
    });

    test('transaksi sebelum 6 minggu diabaikan', () {
      final txs = [_tx('EXPENSE', 50000, DateTime(2026, 8, 23, 12))];
      final buckets = _agg(txs, 'EXPENSE', PeriodGranularity.weekly);
      expect(buckets.every((b) => b.total == 0), isTrue);
    });
  });

  group('monthly', () {
    test('6 bulan termasuk bulan berjalan', () {
      final txs = [
        _tx('INCOME', 5000000, DateTime(2026, 9, 5)),
        _tx('INCOME', 1000000, DateTime(2026, 8, 20)),
        _tx('INCOME', 999999, DateTime(2026, 3, 31)), // di luar jendela
      ];

      final buckets = _agg(txs, 'INCOME', PeriodGranularity.monthly);

      expect(buckets.length, 6);
      expect(buckets[5].total, 5000000); // September
      expect(buckets[4].total, 1000000); // Agustus
      expect(buckets.last.isCurrent, isTrue);
      expect(buckets.last.start.month, 9);
    });

    test('lintas tahun: Jan 2026 => bucket pertama Agu 2025', () {
      final jan = DateTime(2026, 1, 15, 10);
      final txs = [
        _tx('EXPENSE', 2000, DateTime(2025, 12, 25)),
        _tx('EXPENSE', 777777, DateTime(2025, 7, 31)), // di luar jendela
      ];

      final buckets =
          _agg(txs, 'EXPENSE', PeriodGranularity.monthly, now: jan);

      expect(buckets.length, 6);
      expect(buckets.first.start.month, 8);
      expect(buckets.first.start.year, 2025);
      expect(buckets[4].total, 2000); // Desember 2025
      expect(buckets.last.start.month, 1);
      expect(buckets.last.start.year, 2026);
    });
  });

  group('filter umum', () {
    test('income dan expense tidak saling bercampur', () {
      final txs = [
        _tx('EXPENSE', 10000, DateTime(2026, 9, 28, 9)),
        _tx('INCOME', 50000, DateTime(2026, 9, 28, 9)),
        _tx('TRANSFER', 30000, DateTime(2026, 9, 28, 9)),
      ];

      final exp = _agg(txs, 'EXPENSE', PeriodGranularity.daily);
      final inc = _agg(txs, 'INCOME', PeriodGranularity.daily);

      expect(exp.last.total, 10000);
      expect(inc.last.total, 50000);
    });

    test('transaksi bertanggal masa depan diabaikan', () {
      final txs = [_tx('EXPENSE', 12345, DateTime(2026, 9, 29, 9))];
      final buckets = _agg(txs, 'EXPENSE', PeriodGranularity.daily);
      expect(buckets.every((b) => b.total == 0), isTrue);
    });
  });
}
