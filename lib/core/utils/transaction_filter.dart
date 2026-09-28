import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../i18n/app_strings.dart';

/// Shared transaction matching + day grouping for the History and Search
/// screens. Search also matches the nominal, so a user who only remembers
/// "the 50.000 one" still finds it.
class TransactionFilter {
  /// Case-insensitive match against merchant, notes and category name. A query
  /// containing 3+ digits also matches the amount.
  static bool matches(TransactionModel t, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    if ((t.merchantName ?? '').toLowerCase().contains(q)) return true;
    if ((t.notes ?? '').toLowerCase().contains(q)) return true;
    if ((t.category?.name ?? '').toLowerCase().contains(q)) return true;

    // ponytail: plain digits only — no "50rb"/"1jt" unit parsing. Add when
    // users actually type units instead of the plain number.
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 3) {
      return t.amount.round().toString().contains(digits);
    }
    return false;
  }

  static List<TransactionModel> apply(
    List<TransactionModel> source, {
    String query = '',
    String? type,
    String? categoryId,
    String? walletId,
  }) =>
      source.where((t) {
        if (type != null && type != 'ALL' && t.type != type) return false;
        if (categoryId != null && t.categoryId != categoryId) return false;
        if (walletId != null && t.walletId != walletId) return false;
        return matches(t, query);
      }).toList();

  /// Groups by day with TODAY / YESTERDAY / "12 SEP 2026" headers, preserving
  /// source order (newest first).
  static Map<String, List<TransactionModel>> groupByDay(
    List<TransactionModel> txs,
    AppStrings s,
  ) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final out = <String, List<TransactionModel>>{};

    for (final t in txs) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      final String header;
      if (_sameDay(d, now)) {
        header = s.isEn ? 'TODAY' : 'HARI INI';
      } else if (_sameDay(d, yesterday)) {
        header = s.isEn ? 'YESTERDAY' : 'KEMARIN';
      } else {
        header = DateFormat('d MMM yyyy').format(d).toUpperCase();
      }
      out.putIfAbsent(header, () => []).add(t);
    }

    return out;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
