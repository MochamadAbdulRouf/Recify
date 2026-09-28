import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/transaction_filter.dart';
import 'package:recify/data/models/budget_model.dart';
import 'package:recify/data/models/category_model.dart';
import 'package:recify/data/models/transaction_model.dart';
import 'package:recify/domain/notifications/notification_builder.dart';

final _now = DateTime(2026, 9, 20, 12);

TransactionModel _tx({
  required String type,
  required double amount,
  required DateTime date,
  String? categoryId,
  String? merchant,
  String? notes,
  String id = '',
}) =>
    TransactionModel(
      id: id.isEmpty ? '$type-$amount-${date.millisecondsSinceEpoch}' : id,
      walletId: 'w1',
      categoryId: categoryId,
      type: type,
      amount: amount,
      transactionDate: date.millisecondsSinceEpoch,
      merchantName: merchant,
      notes: notes,
      createdAt: date.millisecondsSinceEpoch,
    );

CategoryModel _cat(String id, String name) =>
    CategoryModel(id: id, name: name, type: 'EXPENSE');

BudgetModel _budget(String categoryId, double limit) => BudgetModel(
      id: 'b-$categoryId',
      categoryId: categoryId,
      monthlyLimit: limit,
      month: _now.month,
      year: _now.year,
    );

List<AppNotification> _build(
  List<TransactionModel> txs, {
  List<BudgetModel> budgets = const [],
  List<CategoryModel> categories = const [],
}) =>
    NotificationBuilder.build(
      transactions: txs,
      budgets: budgets,
      categories: categories,
      now: _now,
    );

void main() {
  group('budget alerts', () {
    final cats = [_cat('c1', 'Makanan')];

    test('below 80% of limit => silent', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 790000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ];
      expect(_build(txs, budgets: [_budget('c1', 1000000)], categories: cats),
          isEmpty);
    });

    test('90% of limit => budgetNear, not budgetOver', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 900000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ];
      final out =
          _build(txs, budgets: [_budget('c1', 1000000)], categories: cats);
      expect(out, hasLength(1));
      expect(out.first.kind, NotificationKind.budgetNear);
      expect(out.first.percent, 90);
      expect(out.first.isActionable, isFalse);
    });

    test('120% of limit => budgetOver with the real percent, not capped', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 1200000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ];
      final out =
          _build(txs, budgets: [_budget('c1', 1000000)], categories: cats);
      expect(out.first.kind, NotificationKind.budgetOver);
      expect(out.first.percent, 120);
      expect(out.first.isActionable, isTrue);
    });

    test('income in the same category does not count as spending', () {
      final txs = [
        _tx(
            type: 'INCOME',
            amount: 5000000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ];
      expect(_build(txs, budgets: [_budget('c1', 1000000)], categories: cats),
          isEmpty);
    });

    test('last month spending does not trigger this month budget', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 2000000,
            date: DateTime(2026, 8, 20),
            categoryId: 'c1'),
      ];
      expect(_build(txs, budgets: [_budget('c1', 1000000)], categories: cats),
          isEmpty);
    });

    test('zero limit is ignored instead of dividing by zero', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 50000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ];
      expect(
          _build(txs, budgets: [_budget('c1', 0)], categories: cats), isEmpty);
    });
  });

  group('uncategorized', () {
    test('counts only this month expenses without a category', () {
      final txs = [
        _tx(type: 'EXPENSE', amount: 10000, date: DateTime(2026, 9, 2)),
        _tx(type: 'EXPENSE', amount: 20000, date: DateTime(2026, 9, 3)),
        _tx(
            type: 'EXPENSE',
            amount: 30000,
            date: DateTime(2026, 9, 4),
            categoryId: 'c1'),
        _tx(type: 'EXPENSE', amount: 40000, date: DateTime(2026, 8, 30)),
        _tx(type: 'INCOME', amount: 50000, date: DateTime(2026, 9, 5)),
      ];
      final out = _build(txs);
      expect(out, hasLength(1));
      expect(out.first.kind, NotificationKind.uncategorized);
      expect(out.first.count, 2);
      expect(out.first.amount, 30000);
      expect(out.first.isActionable, isTrue);
    });

    test('nothing uncategorized => no row', () {
      expect(_build([]), isEmpty);
    });
  });

  group('spending spike', () {
    final cats = [_cat('c1', 'Transport')];

    test('5x the 3-month average => spike reported as +400%', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 8, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 7, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 500000,
            date: DateTime(2026, 9, 10),
            categoryId: 'c1'),
      ];
      final out = _build(txs, categories: cats);
      expect(out, hasLength(1));
      expect(out.first.kind, NotificationKind.spendingSpike);
      expect(out.first.percent, 400);
      expect(out.first.reference, 100000);
    });

    test('one quiet month is not a baseline => silent', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 10000,
            date: DateTime(2026, 7, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 900000,
            date: DateTime(2026, 9, 10),
            categoryId: 'c1'),
      ];
      expect(_build(txs, categories: cats), isEmpty);
    });

    test('history older than 3 months is ignored', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 3, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 4, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 900000,
            date: DateTime(2026, 9, 10),
            categoryId: 'c1'),
      ];
      expect(_build(txs, categories: cats), isEmpty);
    });

    test('stable spending month over month => no spike', () {
      final txs = [
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 7, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 8, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 110000,
            date: DateTime(2026, 9, 10),
            categoryId: 'c1'),
      ];
      expect(_build(txs, categories: cats), isEmpty);
    });
  });

  group('ordering and identity', () {
    test('actionable alerts sort above insights', () {
      final cats = [_cat('c1', 'Transport'), _cat('c2', 'Makanan')];
      final txs = [
        // spike material (insight)
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 8, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 100000,
            date: DateTime(2026, 7, 10),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 500000,
            date: DateTime(2026, 9, 10),
            categoryId: 'c1'),
        // over budget (alert)
        _tx(
            type: 'EXPENSE',
            amount: 1200000,
            date: DateTime(2026, 9, 12),
            categoryId: 'c2'),
      ];
      final out = _build(
        txs,
        budgets: [_budget('c2', 1000000)],
        categories: cats,
      );
      expect(out.first.kind, NotificationKind.budgetOver);
      expect(out.last.kind, NotificationKind.spendingSpike);
    });

    test('id is stable per category + month so read state survives', () {
      final cats = [_cat('c1', 'Makanan')];
      final budget = [_budget('c1', 1000000)];
      final first = _build([
        _tx(
            type: 'EXPENSE',
            amount: 900000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
      ], budgets: budget, categories: cats);
      final second = _build([
        _tx(
            type: 'EXPENSE',
            amount: 900000,
            date: DateTime(2026, 9, 5),
            categoryId: 'c1'),
        _tx(
            type: 'EXPENSE',
            amount: 10000,
            date: DateTime(2026, 9, 6),
            categoryId: 'c1'),
      ], budgets: budget, categories: cats);
      expect(first.first.id, second.first.id);
    });
  });

  group('TransactionFilter', () {
    test('matches merchant, notes and category name case-insensitively', () {
      final t = _tx(
        type: 'EXPENSE',
        amount: 25000,
        date: DateTime(2026, 9, 10),
        merchant: 'Indomaret Sudirman',
        notes: 'belanja bulanan',
        categoryId: 'c1',
      );
      final withCat = TransactionModel(
        id: t.id,
        walletId: t.walletId,
        categoryId: t.categoryId,
        type: t.type,
        amount: t.amount,
        transactionDate: t.transactionDate,
        merchantName: t.merchantName,
        notes: t.notes,
        createdAt: t.createdAt,
        category: _cat('c1', 'Belanja Harian'),
      );
      expect(TransactionFilter.matches(withCat, 'indomaret'), isTrue);
      expect(TransactionFilter.matches(withCat, 'BULANAN'), isTrue);
      expect(TransactionFilter.matches(withCat, 'belanja harian'), isTrue);
      expect(TransactionFilter.matches(withCat, 'alfamart'), isFalse);
    });

    test('a 3+ digit query also matches the nominal', () {
      final t =
          _tx(type: 'EXPENSE', amount: 125000, date: DateTime(2026, 9, 10));
      expect(TransactionFilter.matches(t, '125000'), isTrue);
      expect(TransactionFilter.matches(t, '1250'), isTrue);
      expect(TransactionFilter.matches(t, '999'), isFalse);
    });

    test('two-digit queries stay text-only, no amount noise', () {
      final t =
          _tx(type: 'EXPENSE', amount: 125000, date: DateTime(2026, 9, 10));
      expect(TransactionFilter.matches(t, '25'), isFalse);
    });

    test('empty query matches everything', () {
      final t = _tx(type: 'EXPENSE', amount: 1000, date: DateTime(2026, 9, 10));
      expect(TransactionFilter.matches(t, '  '), isTrue);
    });

    test('type filter ALL does not exclude anything', () {
      final txs = [
        _tx(type: 'EXPENSE', amount: 1000, date: DateTime(2026, 9, 10)),
        _tx(type: 'INCOME', amount: 2000, date: DateTime(2026, 9, 11)),
      ];
      expect(TransactionFilter.apply(txs, type: 'ALL'), hasLength(2));
      expect(TransactionFilter.apply(txs, type: 'INCOME'), hasLength(1));
    });
  });
}
