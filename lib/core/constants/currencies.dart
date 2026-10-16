/// Daftar mata uang populer yang didukung aplikasi.
///
/// `code` dipakai sebagai kunci map `rates` dari API open.er-api.com dan
/// sebagai nilai kolom `transactions.currency`. `symbol` hanya untuk
/// tampilan. Daftar sengaja dibatasi ~15 agar menu pemilih tidak panjang.
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption(this.code, this.symbol, this.name);
}

/// Mata uang dasar aplikasi. Semua saldo & total tersimpan dalam IDR.
const String kBaseCurrency = 'IDR';

const List<CurrencyOption> kSupportedCurrencies = [
  CurrencyOption('IDR', 'Rp', 'Rupiah Indonesia'),
  CurrencyOption('USD', r'$', 'Dolar AS'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('JPY', '¥', 'Yen Jepang'),
  CurrencyOption('SGD', 'S\$', 'Dolar Singapura'),
  CurrencyOption('MYR', 'RM', 'Ringgit Malaysia'),
  CurrencyOption('AUD', 'A\$', 'Dolar Australia'),
  CurrencyOption('GBP', '£', 'Pound Sterling'),
  CurrencyOption('CNY', '¥', 'Yuan Tiongkok'),
  CurrencyOption('HKD', 'HK\$', 'Dolar Hong Kong'),
  CurrencyOption('SAR', 'SR', 'Riyal Arab Saudi'),
  CurrencyOption('AED', 'AED', 'Dirham UEA'),
  CurrencyOption('KRW', '₩', 'Won Korea Selatan'),
  CurrencyOption('THB', '฿', 'Baht Thailand'),
  CurrencyOption('INR', '₹', 'Rupee India'),
];

CurrencyOption currencyByCode(String code) {
  return kSupportedCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => kSupportedCurrencies.first,
  );
}
