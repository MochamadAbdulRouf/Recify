import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/category_insight.dart';
import 'package:recify/data/models/category_model.dart';
import 'package:recify/data/models/transaction_model.dart';

// Jendela Daily: 29 Sep – 1 Okt 2026 (start inklusif, end eksklusif).
final _start = DateTime(2026, 9, 29);
final _end = DateTime(2026, 10, 1);

final _food = CategoryModel(
  id: 'c1',
  name: 'Makan',
  type: 'EXPENSE',
  icon: 'food',
  color: '#FF0000',
);
final _bill = CategoryModel(
  id: 'c2',
  name: 'Listrik',
  type: 'EXPENSE',
  icon: 'bill',
  color: '#00FF00',
);

TransactionModel _tx(
  String type,
  double amount,
  DateTime date, {
  CategoryModel? category,
}) =>
    TransactionModel(
      id: '${type}_${date.millisecondsSinceEpoch}_$amount',
      walletId: 'w1',
      type: type,
      amount: amount,
      transactionDate: date.millisecondsSinceEpoch,
      createdAt: date.millisecondsSinceEpoch,
      category: category,
    );

({Map<String, double> totals, Map<String, int> counts, double total})
    _summary(List<TransactionModel> txs, String type) =>
        windowCategorySummary(
          transactions: txs,
          type: type,
          start: _start,
          end: _end,
        );

void main() {
  test('grouping & share per kategori dalam jendela', () {
    final s = _summary([
      _tx('EXPENSE', 50000, DateTime(2026, 9, 29, 8), category: _food),
      _tx('EXPENSE', 30000, DateTime(2026, 9, 30, 12), category: _bill),
      _tx('EXPENSE', 20000, DateTime(2026, 9, 30, 13), category: _food),
    ], 'EXPENSE');

    expect(s.total, 100000);
    expect(s.totals['Makan'], 70000);
    expect(s.totals['Listrik'], 30000);
    expect(s.counts['Makan'], 2);
    expect(s.counts['Listrik'], 1);
  });

  test('transaksi di luar jendela dikecualikan (bug 1 Okt)', () {
    final s = _summary([
      _tx('EXPENSE', 8000, DateTime(2026, 9, 30, 9), category: _food),
      // Bulan lalu tapi masih di jendela Daily → tetap masuk:
      _tx('EXPENSE', 5000, DateTime(2026, 9, 29, 7), category: _bill),
      // Di luar jendela:
      _tx('EXPENSE', 99999, DateTime(2026, 9, 28, 23), category: _food),
      _tx('EXPENSE', 99999, DateTime(2026, 10, 1, 0), category: _food),
    ], 'EXPENSE');

    expect(s.total, 13000);
    expect(s.totals['Makan'], 8000);
    expect(s.totals['Listrik'], 5000);
  });

  test('filter type: EXPENSE dan INCOME tidak bercampur', () {
    final txs = [
      _tx('EXPENSE', 10000, DateTime(2026, 9, 30, 9), category: _food),
      _tx('INCOME', 80000, DateTime(2026, 9, 30, 10),
          category: CategoryModel(
            id: 'c9',
            name: 'Gaji',
            type: 'INCOME',
            icon: 'work',
            color: '#0000FF',
          )),
    ];

    expect(_summary(txs, 'EXPENSE').total, 10000);
    expect(_summary(txs, 'INCOME').total, 80000);
    expect(_summary(txs, 'INCOME').totals.containsKey('Makan'), isFalse);
  });

  test('jendela kosong → total 0, maps kosong', () {
    final s = _summary(
      [_tx('EXPENSE', 10000, DateTime(2026, 1, 1))],
      'EXPENSE',
    );

    expect(s.total, 0);
    expect(s.totals, isEmpty);
    expect(s.counts, isEmpty);
  });

  test('kategori null jatuh ke fallbackName', () {
    final s = _summary(
      [_tx('EXPENSE', 10000, DateTime(2026, 9, 30, 9))],
      'EXPENSE',
    );
    expect(s.totals.keys.single, 'Umum');

    final localized = windowCategorySummary(
      transactions: [_tx('EXPENSE', 10000, DateTime(2026, 9, 30, 9))],
      type: 'EXPENSE',
      start: _start,
      end: _end,
      fallbackName: 'General',
    );
    expect(localized.totals.keys.single, 'General');
  });
}
