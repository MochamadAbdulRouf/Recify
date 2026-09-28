import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

/// What kind of alert this is. Drives icon + colour + section in the UI.
enum NotificationKind { budgetOver, budgetNear, spendingSpike, uncategorized }

/// An in-app alert derived purely from data already on the device.
///
/// There is no push notification and no server: the bell is a *feed* built at
/// read time. [id] is stable per category + calendar month, so the read state
/// stored in SharedPreferences survives rebuilds and new transactions.
class AppNotification {
  final String id;
  final NotificationKind kind;

  /// Category display name, when the alert is about one category.
  final String? categoryName;

  /// Percentage used in the headline (budget usage, or % above average).
  final int percent;

  /// Amount the alert is about: spent, or this month's spend for a spike.
  final double amount;

  /// Comparison figure: the budget limit, or the 3-month average.
  final double reference;

  /// Number of records involved (uncategorized count).
  final int count;

  const AppNotification({
    required this.id,
    required this.kind,
    this.categoryName,
    this.percent = 0,
    this.amount = 0,
    this.reference = 0,
    this.count = 0,
  });

  /// Alert = user should act. Insight = worth knowing, nothing to do.
  bool get isActionable =>
      kind == NotificationKind.budgetOver ||
      kind == NotificationKind.uncategorized;
}

/// Pure builder: transactions + budgets + categories in, alerts out.
///
/// Kept free of Flutter and of [AppStrings] so it can be unit-tested and so
/// the UI owns all wording (i18n).
class NotificationBuilder {
  /// Budget usage that counts as "nearly there".
  static const double nearThreshold = 0.8;

  /// This month must be at least this many times the recent average.
  static const double spikeThreshold = 1.5;

  /// Months of history that must have spending before a spike is claimed.
  static const int spikeMinActiveMonths = 2;

  static const int maxItems = 12;

  static List<AppNotification> build({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<CategoryModel> categories,
    required DateTime now,
  }) {
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final nameById = {for (final c in categories) c.id: c.name};

    final out = <AppNotification>[
      ..._budgetAlerts(budgets, transactions, nameById, now, monthKey),
      ..._uncategorized(transactions, now, monthKey),
      ..._spikes(transactions, nameById, now, monthKey),
    ];

    out.sort((a, b) {
      final byAction = (b.isActionable ? 1 : 0) - (a.isActionable ? 1 : 0);
      if (byAction != 0) return byAction;
      return b.percent.compareTo(a.percent);
    });

    return out.length > maxItems ? out.sublist(0, maxItems) : out;
  }

  static List<AppNotification> _budgetAlerts(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
    Map<String, String> nameById,
    DateTime now,
    String monthKey,
  ) {
    final out = <AppNotification>[];

    for (final b in budgets) {
      if (b.month != now.month || b.year != now.year || b.monthlyLimit <= 0) {
        continue;
      }

      var spent = 0.0;
      for (final t in transactions) {
        if (t.type != 'EXPENSE' || t.categoryId != b.categoryId) continue;
        final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
        if (d.month != now.month || d.year != now.year) continue;
        spent += t.amount;
      }
      if (spent <= 0) continue;

      final ratio = spent / b.monthlyLimit;
      if (ratio < nearThreshold) continue;

      final name = nameById[b.categoryId] ?? '';
      final over = ratio >= 1.0;
      out.add(
        AppNotification(
          id: '${over ? 'budgetOver' : 'budgetNear'}:${b.categoryId}:$monthKey',
          kind:
              over ? NotificationKind.budgetOver : NotificationKind.budgetNear,
          categoryName: name,
          percent: (ratio * 100).round(),
          amount: spent,
          reference: b.monthlyLimit,
        ),
      );
    }

    return out;
  }

  static List<AppNotification> _uncategorized(
    List<TransactionModel> transactions,
    DateTime now,
    String monthKey,
  ) {
    var count = 0;
    var total = 0.0;
    for (final t in transactions) {
      if (t.type != 'EXPENSE' || t.categoryId != null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      if (d.month != now.month || d.year != now.year) continue;
      count++;
      total += t.amount;
    }
    if (count == 0) return const [];

    return [
      AppNotification(
        id: 'uncategorized:$monthKey',
        kind: NotificationKind.uncategorized,
        amount: total,
        count: count,
      ),
    ];
  }

  /// This month vs the average of the previous 3 calendar months, per category.
  ///
  /// Only months that actually had spending in that category count towards the
  /// average, and at least [spikeMinActiveMonths] of them must exist — a single
  /// old purchase is not a baseline. That keeps the alert from firing on noise
  /// for a category the user rarely uses.
  static List<AppNotification> _spikes(
    List<TransactionModel> transactions,
    Map<String, String> nameById,
    DateTime now,
    String monthKey,
  ) {
    final current = <String, double>{};
    final history = <String, Map<String, double>>{};

    for (final t in transactions) {
      if (t.type != 'EXPENSE' || t.categoryId == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      final monthsBack = (now.year - d.year) * 12 + (now.month - d.month);
      if (monthsBack < 0 || monthsBack > 3) continue;

      if (monthsBack == 0) {
        current[t.categoryId!] = (current[t.categoryId!] ?? 0) + t.amount;
      } else {
        final perMonth = history.putIfAbsent(t.categoryId!, () => {});
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        perMonth[key] = (perMonth[key] ?? 0) + t.amount;
      }
    }

    final out = <AppNotification>[];
    for (final entry in current.entries) {
      final months = history[entry.key];
      if (months == null || months.length < spikeMinActiveMonths) continue;

      final avg = months.values.reduce((a, b) => a + b) / months.length;
      if (avg <= 0) continue;

      final ratio = entry.value / avg;
      if (ratio < spikeThreshold) continue;

      out.add(
        AppNotification(
          id: 'spike:${entry.key}:$monthKey',
          kind: NotificationKind.spendingSpike,
          categoryName: nameById[entry.key] ?? '',
          percent: ((ratio - 1) * 100).round(),
          amount: entry.value,
          reference: avg,
        ),
      );
    }

    return out;
  }
}
