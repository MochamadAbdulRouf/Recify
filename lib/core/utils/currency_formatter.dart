import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {bool isExpense = false, bool showSign = false}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final formatted = formatter.format(amount.abs());
    if (showSign) {
      return isExpense ? '-$formatted' : '+$formatted';
    }
    return formatted;
  }

  static String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
