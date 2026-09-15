import '../../data/models/transaction_model.dart';
import 'currency_formatter.dart';

/// How the balance-trend pill should render.
enum TrendMode {
  /// Nothing moved this week (or no balance to compare against) => show "—".
  none,

  /// Percent would round to 0.0% => show the rupiah amount instead.
  nominal,

  /// Percent is meaningful => show it.
  percent,
}

/// Weekly balance trend: net flow of the current week measured against the
/// wallet's current balance. Because the divisor is a real balance (not a
/// previous week that may be empty), the percentage is meaningful from day one
/// and never explodes to a fake 100%.
class BalanceTrend {
  final TrendMode mode;

  /// Percent when [mode] is [TrendMode.percent], rupiah amount when
  /// [TrendMode.nominal], 0 otherwise.
  final double value;

  const BalanceTrend._(this.mode, this.value);

  static const BalanceTrend none = BalanceTrend._(TrendMode.none, 0);

  bool get isPositive => value > 0;
  bool get isFlat => mode == TrendMode.none || value == 0;

  /// Exactly what the pill shows: "+30,3%", "+Rp 20.000" or "—".
  String get label {
    switch (mode) {
      case TrendMode.none:
        return '—';
      case TrendMode.percent:
        return '${isPositive ? '+' : '-'}${value.abs().toStringAsFixed(1)}%';
      case TrendMode.nominal:
        return '${isPositive ? '+' : '-'}${CurrencyFormatter.formatRupiah(value.abs())}';
    }
  }
}

class TrendCalculator {
  /// Below this percent the display would round to "0.0%" and lie about the
  /// movement, so we fall back to the nominal amount.
  static const double nominalThresholdPercent = 0.1;

  static BalanceTrend weeklyBalanceTrend({
    required List<TransactionModel> transactions,
    required double currentBalance,
    required DateTime now,
  }) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    final net = transactions
        .where((t) {
          final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
          return !d.isBefore(weekStart) && d.isBefore(now);
        })
        .fold(0.0, (sum, t) => sum + (t.type == 'INCOME' ? t.amount : -t.amount));

    if (net == 0) return BalanceTrend.none;

    // abs() keeps the sign tied to the flow direction when the balance is
    // negative (debt) instead of flipping it.
    final base = currentBalance.abs();
    if (base == 0) return BalanceTrend._(TrendMode.nominal, net);

    final pct = (net / base) * 100;
    if (pct.abs() < nominalThresholdPercent) {
      return BalanceTrend._(TrendMode.nominal, net);
    }
    return BalanceTrend._(TrendMode.percent, pct);
  }
}
