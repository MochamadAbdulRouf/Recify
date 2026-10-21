import 'package:intl/intl.dart';

import '../constants/currencies.dart';

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

  /// Jumlah desimal standar per kode (ISO 4217): 0 untuk IDR/JPY/KRW,
  /// 2 untuk sisanya. Hasil: $12.50, bukan Rp12.50.
  static int _decimalDigitsFor(String code) =>
      code == 'IDR' || code == 'JPY' || code == 'KRW' ? 0 : 2;

  /// Format nominal dalam mata uang [code] dengan simbol kode tersebut,
  /// mis. formatForeign(12.5, 'USD') → '$12.50'.
  static String formatForeign(
    double amount,
    String code, {
    bool isExpense = false,
    bool showSign = false,
  }) {
    final option = currencyByCode(code);
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: option.symbol,
      decimalDigits: _decimalDigitsFor(code),
    );
    final formatted = formatter.format(amount.abs());
    if (showSign) {
      return isExpense ? '-$formatted' : '+$formatted';
    }
    return formatted;
  }

  /// Format nominal sesuai mata uang transaksi. [amountIdr] nilai tersimpan
  /// (selalu IDR); [currency] kode mata uang asli. Transaksi IDR memakai
  /// format lama. Transaksi asing butuh [originalAmount] hasil reverse-
  /// convert dari pemanggil; bila null (kurs hilang) jatuh ke format IDR.
  static String formatTransaction(
    double amountIdr,
    String currency, {
    double? originalAmount,
    bool isExpense = false,
    bool showSign = false,
  }) {
    if (currency == kBaseCurrency || originalAmount == null) {
      return format(amountIdr, isExpense: isExpense, showSign: showSign);
    }
    return formatForeign(
      originalAmount,
      currency,
      isExpense: isExpense,
      showSign: showSign,
    );
  }
}
