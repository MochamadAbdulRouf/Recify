import '../../data/models/transaction_model.dart';

/// Rekap per-kategori dalam jendela [start, end) — sumber angka Smart Insight
/// dan Spending by Category supaya keduanya selalu sinkron dengan chart
/// (jendela tab Daily/Weekly/Monthly: `buckets.first.start` →
/// `buckets.last.end`).
///
/// Window setengah-terbuka, sama seperti `PeriodAggregator`: transaksi
/// cocok bila `start <= tanggal < end`. Tipe difilter; kategori kosong
/// jatuh ke 'Umum'.
({Map<String, double> totals, Map<String, int> counts, double total})
    windowCategorySummary({
  required List<TransactionModel> transactions,
  required String type,
  required DateTime start,
  required DateTime end,
  String fallbackName = 'Umum',
}) {
  final totals = <String, double>{};
  final counts = <String, int>{};
  var total = 0.0;
  for (final t in transactions) {
    if (t.type != type) continue;
    final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
    if (d.isBefore(start) || !d.isBefore(end)) continue;
    final name = t.category?.name ?? fallbackName;
    totals[name] = (totals[name] ?? 0) + t.amount;
    counts[name] = (counts[name] ?? 0) + 1;
    total += t.amount;
  }
  return (totals: totals, counts: counts, total: total);
}
