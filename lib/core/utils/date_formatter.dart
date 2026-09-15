import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatRelative(int timestampMs, {bool isEn = false}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(date);
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return isEn ? 'Today, $time' : 'Hari ini, $time';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day) {
      return isEn ? 'Yesterday, $time' : 'Kemarin, $time';
    }
    return DateFormat('d MMM, HH:mm').format(date);
  }
}
