import '../../data/models/transaction_model.dart';

/// Granularitas jendela waktu tab Statistik.
enum PeriodGranularity { daily, weekly, monthly }

/// Satu bar grafik: total + jumlah transaksi dalam satu rentang waktu.
class PeriodBucket {
  /// Awal periode (inklusif).
  final DateTime start;

  /// Akhir periode (eksklusif).
  final DateTime end;

  /// Jumlah [amount] untuk tipe yang dipilih.
  final double total;

  /// Jumlah transaksi yang masuk bucket ini.
  final int count;

  /// True untuk periode yang masih berjalan (belum penuh).
  /// UI harus menandainya (mis. opacity lebih redup) supaya tidak dibaca
  /// sebagai penurunan.
  final bool isCurrent;

  const PeriodBucket({
    required this.start,
    required this.end,
    required this.total,
    required this.count,
    required this.isCurrent,
  });
}

/// Agregasi murni (tanpa Flutter) dari transaksi → bucket per periode.
///
/// Sumber tanggal: [TransactionModel.transactionDate] — tanggal transaksi
/// yang dipahami user. BUKAN `createdAt` (waktu input).
/// Transaksi bertanggal masa depan atau di luar jendela diabaikan.
class PeriodAggregator {
  /// Tab Daily: N hari terakhir termasuk hari ini (rolling).
  static const int dailyWindow = 3;

  /// Tab Weekly: N minggu ISO terakhir (Senin–Minggu), termasuk minggu ini.
  static const int weeklyWindow = 6;

  /// Tab Monthly: N bulan kalender terakhir, termasuk bulan ini.
  static const int monthlyWindow = 6;

  static List<PeriodBucket> aggregate({
    required List<TransactionModel> transactions,
    required String type, // 'EXPENSE' | 'INCOME'
    required PeriodGranularity granularity,
    required DateTime now,
  }) {
    final ranges = _buildRanges(granularity: granularity, now: now);
    final totals = List<double>.filled(ranges.length, 0.0);
    final counts = List<int>.filled(ranges.length, 0);

    for (final tx in transactions) {
      if (tx.type != type) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      for (var i = 0; i < ranges.length; i++) {
        final r = ranges[i];
        if (!d.isBefore(r.start) && d.isBefore(r.end)) {
          totals[i] += tx.amount;
          counts[i] += 1;
          break; // rentang tidak tumpang tindih
        }
      }
    }

    return List<PeriodBucket>.generate(
      ranges.length,
      (i) => PeriodBucket(
        start: ranges[i].start,
        end: ranges[i].end,
        total: totals[i],
        count: counts[i],
        isCurrent: i == ranges.length - 1,
      ),
    );
  }

  static List<({DateTime start, DateTime end})> _buildRanges({
    required PeriodGranularity granularity,
    required DateTime now,
  }) {
    switch (granularity) {
      case PeriodGranularity.daily:
        final today = DateTime(now.year, now.month, now.day);
        return List.generate(dailyWindow, (i) {
          final start = today.subtract(Duration(days: dailyWindow - 1 - i));
          return (start: start, end: start.add(const Duration(days: 1)));
        });
      case PeriodGranularity.weekly:
        final thisMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - DateTime.monday));
        return List.generate(weeklyWindow, (i) {
          final start =
              thisMonday.subtract(Duration(days: 7 * (weeklyWindow - 1 - i)));
          return (start: start, end: start.add(const Duration(days: 7)));
        });
      case PeriodGranularity.monthly:
        return List.generate(monthlyWindow, (i) {
          final monthIndex = (now.year * 12 + (now.month - 1)) -
              (monthlyWindow - 1 - i);
          final start = DateTime(monthIndex ~/ 12, (monthIndex % 12) + 1, 1);
          final end = monthIndex % 12 == 11
              ? DateTime((monthIndex ~/ 12) + 1, 1, 1)
              : DateTime(monthIndex ~/ 12, (monthIndex % 12) + 2, 1);
          return (start: start, end: end);
        });
    }
  }
}
