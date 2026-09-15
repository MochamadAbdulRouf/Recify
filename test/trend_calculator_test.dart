import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/trend_calculator.dart';
import 'package:recify/data/models/transaction_model.dart';

// Fixed "now": Wednesday 16 Sep 2026 => week starts Mon 14 Sep.
final _now = DateTime(2026, 9, 16, 12);

TransactionModel _tx(String type, double amount, DateTime date) => TransactionModel(
      id: '${type}_${amount}_${date.millisecondsSinceEpoch}',
      walletId: 'w1',
      type: type,
      amount: amount,
      transactionDate: date.millisecondsSinceEpoch,
      createdAt: date.millisecondsSinceEpoch,
    );

BalanceTrend _calc(List<TransactionModel> txs, double balance) =>
    TrendCalculator.weeklyBalanceTrend(
      transactions: txs,
      currentBalance: balance,
      now: _now,
    );

void main() {
  group('weeklyBalanceTrend', () {
    test('no activity this week => none (renders as dash)', () {
      expect(_calc([], 1000000).mode, TrendMode.none);
    });

    test('income equals expense => none, not a fake 0.0%', () {
      final txs = [
        _tx('INCOME', 20000, DateTime(2026, 9, 15)),
        _tx('EXPENSE', 20000, DateTime(2026, 9, 15)),
      ];
      expect(_calc(txs, 1000000).mode, TrendMode.none);
    });

    test('tiny income on a big balance => nominal, never a lying +0.0%', () {
      // 5.000 / 16.498.900 = 0.03% which would round to +0.0%
      final txs = [_tx('INCOME', 5000, DateTime(2026, 9, 15))];
      final trend = _calc(txs, 16498900);
      expect(trend.mode, TrendMode.nominal);
      expect(trend.value, 5000);
      expect(trend.isPositive, isTrue);
    });

    test('income 20.000 on 16.5jt balance => 0.12% is above threshold, percent', () {
      final txs = [_tx('INCOME', 20000, DateTime(2026, 9, 15))];
      final trend = _calc(txs, 16498900);
      expect(trend.mode, TrendMode.percent);
      expect(trend.value, closeTo(0.121, 0.001));
      expect(trend.isPositive, isTrue);
    });

    test('income 20.000 on a 100jt balance => nominal again', () {
      final txs = [_tx('INCOME', 20000, DateTime(2026, 9, 15))];
      expect(_calc(txs, 100000000).mode, TrendMode.nominal);
    });

    test('income 20.000 + expense 10.000 => net +10.000, green', () {
      final txs = [
        _tx('INCOME', 20000, DateTime(2026, 9, 15)),
        _tx('EXPENSE', 10000, DateTime(2026, 9, 15)),
      ];
      final trend = _calc(txs, 16498900);
      expect(trend.value, greaterThan(0));
      expect(trend.isPositive, isTrue);
    });

    test('expense bigger than income => negative (red)', () {
      final txs = [
        _tx('INCOME', 10000, DateTime(2026, 9, 15)),
        _tx('EXPENSE', 500000, DateTime(2026, 9, 15)),
      ];
      final trend = _calc(txs, 16498900);
      expect(trend.value, lessThan(0));
      expect(trend.isPositive, isFalse);
    });

    test('large income produces a real percentage, not a capped 100%', () {
      final txs = [_tx('INCOME', 5000000, DateTime(2026, 9, 15))];
      final trend = _calc(txs, 16498900);
      expect(trend.mode, TrendMode.percent);
      expect(trend.value, closeTo(30.3, 0.1));
    });

    test('negative balance keeps sign tied to flow direction', () {
      final txs = [_tx('INCOME', 500000, DateTime(2026, 9, 15))];
      final trend = _calc(txs, -1000000);
      expect(trend.isPositive, isTrue);
    });

    test('zero balance with movement => nominal', () {
      final txs = [_tx('INCOME', 20000, DateTime(2026, 9, 15))];
      final trend = _calc(txs, 0);
      expect(trend.mode, TrendMode.nominal);
      expect(trend.value, 20000);
    });

    test('last week and older transactions are ignored', () {
      final txs = [
        _tx('INCOME', 900000, DateTime(2026, 9, 8)),
        _tx('EXPENSE', 900000, DateTime(2026, 8, 20)),
      ];
      expect(_calc(txs, 16498900).mode, TrendMode.none);
    });

    test('future-dated entries do not leak into this week', () {
      final txs = [_tx('INCOME', 900000, DateTime(2026, 9, 25))];
      expect(_calc(txs, 16498900).mode, TrendMode.none);
    });
  });

  group('pill label', () {
    test('no movement => dash', () {
      expect(_calc([], 16498900).label, '—');
    });

    test('tiny income => nominal rupiah with + sign', () {
      final txs = [_tx('INCOME', 5000, DateTime(2026, 9, 15))];
      expect(_calc(txs, 16498900).label, '+Rp 5.000');
    });

    test('expense-dominated week => negative label', () {
      final txs = [
        _tx('INCOME', 10000, DateTime(2026, 9, 15)),
        _tx('EXPENSE', 100000, DateTime(2026, 9, 15)),
      ];
      // -90.000 / 16.498.900 = -0.545% => above threshold, so percent.
      expect(_calc(txs, 16498900).label, '-0.5%');
    });

    test('expense just under the threshold => nominal rupiah', () {
      final txs = [
        _tx('INCOME', 10000, DateTime(2026, 9, 15)),
        _tx('EXPENSE', 25000, DateTime(2026, 9, 15)),
      ];
      // -15.000 / 16.498.900 = -0.09% => below 0.1%, so nominal.
      expect(_calc(txs, 16498900).label, '-Rp 15.000');
    });

    test('big income => percentage with one decimal', () {
      final txs = [_tx('INCOME', 5000000, DateTime(2026, 9, 15))];
      expect(_calc(txs, 16498900).label, '+30.3%');
    });

    test('big expense => negative percentage', () {
      final txs = [_tx('EXPENSE', 5000000, DateTime(2026, 9, 15))];
      expect(_calc(txs, 16498900).label, '-30.3%');
    });
  });
}
