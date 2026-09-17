import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/locale_provider.dart';

/// App-wide UI strings. Transaction data (merchant, category names) is NOT
/// translated — it stays exactly as the user recorded it.
class AppStrings {
  final bool isEn;
  const AppStrings(this.isEn);

  static AppStrings of(BuildContext context) =>
      AppStrings(context.read<LocaleProvider>().isEn);

  // ── Shell / Nav ──
  String get home => isEn ? 'Home' : 'Beranda';
  String get statistics => isEn ? 'Stats' : 'Statistik';
  String get history => isEn ? 'History' : 'Riwayat';
  String get account => isEn ? 'Account' : 'Akun';

  // ── Home ──
  String get appTagline =>
      isEn ? 'Expense Tracker & Local OCR' : 'Pelacak Pengeluaran & OCR Lokal';
  String get totalBalance => isEn ? 'TOTAL BALANCE' : 'TOTAL SALDO';
  String get income => isEn ? 'Income' : 'Pemasukan';
  String get expense => isEn ? 'Expense' : 'Pengeluaran';
  String get recentActivity => isEn ? 'Recent Activity' : 'Aktivitas Terbaru';
  String get viewAll => isEn ? 'View All' : 'Lihat Semua';
  String get scanReceipt => isEn ? 'Scan Receipt' : 'Pindai Struk Belanja';
  String get scanReceiptSubtitle => isEn
      ? 'Local AI extraction of totals & items'
      : 'Ekstraksi total harga & item secara lokal (AI)';
  String get manualEntry => isEn ? 'Manual Entry' : 'Catat Manual';
  String get exportReport => isEn ? 'Export Report' : 'Ekspor Laporan';
  String get noTransactionsYet =>
      isEn ? 'No transactions recorded' : 'Belum ada transaksi tercatat';
  String get noTransactionsHint => isEn
      ? 'Snap a receipt photo or record an expense'
      : 'Ambil foto nota atau catat pengeluaran Anda';
  String get startScan => isEn ? 'Start Scanning' : 'Mulai Scan Nota';

  // ── Hero card status ──
  String get walletActive => isEn ? 'Wallet Active' : 'Dompet Aktif';
  String get updated => isEn ? 'Updated' : 'Diperbarui';
  String get justNow => isEn ? 'just now' : 'baru saja';
  String get minutesAgoShort => isEn ? 'min ago' : 'mnt lalu';
  String get hoursAgoShort => isEn ? 'h ago' : 'jam lalu';
  String get noDataYet => isEn ? 'no data yet' : 'belum ada data';
  String get thisWeek => isEn ? 'this week' : 'minggu ini';
  String receiptsToday(int n) =>
      isEn ? '$n recorded today' : '$n tercatat hari ini';
  String get allWallets => isEn ? 'All Wallets' : 'Semua Dompet';

  // ── Greeting ──
  String greetingFor(int hour) {
    if (hour < 12) return isEn ? 'Good morning' : 'Selamat pagi';
    if (hour < 17) return isEn ? 'Good afternoon' : 'Selamat siang';
    if (hour < 20) return isEn ? 'Good evening' : 'Selamat sore';
    return isEn ? 'Good night' : 'Selamat malam';
  }

  // ── Insights ──
  String get insightTitle => isEn ? 'Smart Insight' : 'Analisis Cerdas';
  String get insightEmpty => isEn
      ? 'Record spending to unlock insights'
      : 'Catat pengeluaran untuk melihat analisis';
  String insightTopCategory(String category, int percent) => isEn
      ? '$category takes $percent% of this month\'s spending'
      : '$category menyerap $percent% pengeluaran bulan ini';
  String get insightOnTrack => isEn
      ? 'Spending is within your usual pattern'
      : 'Pengeluaran masih dalam pola biasanya';
  String get exportTaxReport =>
      isEn ? 'Export Monthly Report' : 'Ekspor Laporan Bulanan';
  String get exportTaxReportHint =>
      isEn ? 'CSV ready for your records' : 'CSV siap untuk arsip Anda';
  String activeCount(int n) => isEn ? '$n active' : '$n aktif';
  String get tapBarHint =>
      isEn ? 'Tap a bar to see that day' : 'Ketuk batang untuk lihat hari itu';
  String get totalLabel => isEn ? 'Total' : 'Total';

  // ── Manual entry ──
  String get manualEntryTitle =>
      isEn ? 'Manual Transaction' : 'Catat Transaksi Manual';
  String get typeExpense => isEn ? 'IDR • Expense' : 'IDR • Pengeluaran';
  String get typeIncome => isEn ? 'IDR • Income' : 'IDR • Pemasukan';
  String get categorySectionTitle =>
      isEn ? 'Transaction Category' : 'Kategori Transaksi';
  String get swipeToPick => isEn ? 'Swipe to pick' : 'Geser untuk pilih';
  String get nameLabel =>
      isEn ? 'Transaction / Merchant Name' : 'Nama Transaksi / Tempat';
  String get nameHintExpense => isEn
      ? 'e.g. Coffee shop, Fuel, Groceries'
      : 'Contoh: Kopi Kenangan, Beli Bensin, Indomaret';
  String get nameHintIncome => isEn
      ? 'e.g. Monthly salary, Bonus, Transfer in'
      : 'Contoh: Gaji Bulanan, Bonus, Transfer Masuk';
  String get dateLabel => isEn ? 'Transaction Date' : 'Tanggal Transaksi';
  String get walletLabel => isEn ? 'Payment Wallet' : 'Dompet Pembayaran';
  String get chooseWallet => isEn ? 'Choose Wallet' : 'Pilih Dompet';
  String get notesLabel =>
      isEn ? 'Additional Notes (Optional)' : 'Catatan Tambahan (Opsional)';
  String get notesHint =>
      isEn ? 'Description or item breakdown…' : 'Keterangan atau rincian item…';
  String get cancel => isEn ? 'Cancel' : 'Batal';
  String get saveTransaction => isEn ? 'Save Transaction' : 'Simpan Transaksi';
  String get selectWalletTitle =>
      isEn ? 'Choose Wallet / Source' : 'Pilih Dompet / Sumber Dana';
  String get balanceLabel => isEn ? 'Balance' : 'Saldo';
  String get errAmount =>
      isEn ? 'Enter a valid amount' : 'Masukkan nominal transaksi yang valid';
  String get errCategoryWallet => isEn
      ? 'Pick a category and a wallet'
      : 'Pilih kategori dan dompet transaksi';
  String savedTransaction(String name, String amount) => isEn
      ? 'Transaction "$name" of $amount saved!'
      : 'Transaksi "$name" sebesar $amount berhasil disimpan!';

  // ── OCR verification ──
  String get verifyDetails => isEn ? 'Verify Details' : 'Verifikasi Detail';
  String get reviewExtracted => isEn
      ? 'Review extracted data before saving.'
      : 'Periksa data hasil ekstraksi sebelum disimpan.';
  String get parserGemini => 'Gemini AI';
  String get parserOffline => isEn ? 'Offline Parser' : 'Parser Offline';
  String get statusNotValidated => isEn ? 'Not Validated' : 'Belum Divalidasi';
  String get statusValid => 'Valid';
  String get statusCheck => isEn ? 'Check' : 'Periksa';
  String get statusNeedsReview => isEn ? 'Needs Review' : 'Perlu Review';
  String get ocrActive => 'OCR ACTIVE';
  String get fieldAmount => isEn ? 'AMOUNT' : 'NOMINAL';
  String get fieldDate => isEn ? 'DATE' : 'TANGGAL';
  String get fieldMerchant => isEn ? 'MERCHANT / STORE' : 'TOKO / MERCHANT';
  String get fieldCategory => isEn ? 'CATEGORY' : 'KATEGORI';
  String get fieldWallet => isEn ? 'PAID FROM WALLET' : 'SUMBER DOMPET';
  String get merchantHint => isEn
      ? 'Store name (e.g. Indomaret, Starbucks)'
      : 'Nama Toko (mis. Indomaret, Starbucks)';
  String get retake => isEn ? 'Retake' : 'Foto Ulang';
  String get confirm => isEn ? 'Confirm' : 'Konfirmasi';
  String receiptItems(int n) =>
      isEn ? 'Receipt Items ($n items)' : 'Rincian Belanja ($n item)';
  String get useToday => isEn ? 'Use Today' : 'Pakai Hari Ini';
  String staleDateWarning(String date, String ago) => isEn
      ? 'Receipt date: $date ($ago) — not counted in this month. Tap to change.'
      : 'Tanggal struk: $date ($ago) — tidak masuk rekap bulan ini. Tap di sini untuk ubah.';
  String get errAmountZero =>
      isEn ? 'Amount must be greater than 0!' : 'Nominal harus lebih dari 0!';
  String get errPickCategory =>
      isEn ? 'Pick a category first!' : 'Pilih kategori terlebih dahulu!';
  String get errPickWallet =>
      isEn ? 'Pick a wallet first!' : 'Pilih dompet/wallet terlebih dahulu!';
  String savedScan(String merchant, String amount) => isEn
      ? 'Transaction $merchant of $amount saved!'
      : 'Transaksi $merchant sebesar $amount tersimpan!';
  String saveFailed(String err) => isEn
      ? 'Failed to save transaction: $err'
      : 'Gagal menyimpan transaksi: $err';

  // ── Scan sheet ──
  String get chooseSource =>
      isEn ? 'Choose Receipt Source' : 'Pilih Sumber Foto Nota';
  String get cameraOption => isEn ? 'Take Photo' : 'Ambil Foto Kamera';
  String get cameraOptionHint => isEn
      ? 'Scan receipt instantly with on-device OCR'
      : 'Scan nota langsung dengan OCR on-device';
  String get galleryOption => isEn ? 'Pick from Gallery' : 'Pilih dari Galeri';
  String get galleryOptionHint => isEn
      ? 'Pick a receipt image from your gallery'
      : 'Pilih gambar nota dari galeri';
  String get scanTargetHint => isEn
      ? 'Point the camera at your receipt'
      : 'Arahkan kamera ke struk belanja';
  String get instantOcrHint => isEn
      ? 'Instant on-device OCR extraction'
      : 'Ekstraksi OCR otomatis secara instan di HP Anda';
  String get scanReceiptNav => isEn ? 'Scan Receipt' : 'Pindai Struk / Nota';

  // ── Stats ──
  String get statsTitle =>
      isEn ? 'Statistics & Analysis' : 'Statistik & Analisis';
  String get statsSubtitle =>
      isEn ? 'Spending & Cash Flow Report' : 'Laporan Pengeluaran & Arus Kas';
  String get daily => isEn ? 'Daily' : 'Harian';
  String get weekly => isEn ? 'Weekly' : 'Mingguan';
  String get monthly => isEn ? 'Monthly' : 'Bulanan';
  String get totalSpending => isEn ? 'Total Spending' : 'Total Pengeluaran';
  String get noSpending => isEn ? 'No spending' : 'Tidak ada pengeluaran';
  String get categoryBreakdown =>
      isEn ? 'Spending by Category' : 'Rincian Kategori Pengeluaran';
  String get categoriesLabel => isEn ? 'Categories' : 'Kategori';
  String get transactionsLabel => isEn ? 'Transactions' : 'Transaksi';
  String get noSpendingData =>
      isEn ? 'No spending data yet' : 'Belum ada data pengeluaran';
  String get noSpendingDataHint => isEn
      ? 'Record a transaction or scan a receipt to see visual stats.'
      : 'Catat transaksi atau pindai struk untuk melihat statistik visual.';

  // ── History ──
  String get historyTitle => isEn ? 'Transaction History' : 'Riwayat Transaksi';
  String historyCount(int n) =>
      isEn ? '$n transactions recorded' : '$n transaksi tercatat';
  String get searchHint => isEn
      ? 'Search transactions, merchants, notes…'
      : 'Cari transaksi, merchant, catatan…';
  String get filterAll => isEn ? 'All' : 'Semua';
  String get filterExpense => isEn ? 'Expense' : 'Pengeluaran';
  String get filterIncome => isEn ? 'Income' : 'Pemasukan';
  String get exportCsv => isEn ? 'Export CSV' : 'Ekspor CSV';
  String get emptyHistoryTitle =>
      isEn ? 'No transactions found' : 'Tidak ada transaksi ditemukan';
  String get emptyHistoryHint => isEn
      ? 'Try different keywords or filters'
      : 'Coba ubah kata kunci pencarian atau filter';

  // ── Settings ──
  String get settingsTitle => isEn ? 'Settings' : 'Pengaturan';
  String get language => isEn ? 'Language' : 'Bahasa';
  String get languageSubtitle =>
      isEn ? 'Switch app language' : 'Ganti bahasa aplikasi';
  String get english => isEn ? 'English' : 'Inggris';
  String get indonesian => isEn ? 'Indonesian' : 'Indonesia';

  // ── Common ──
  String get exportFailed => isEn ? 'Export failed: ' : 'Gagal ekspor: ';
  String get reportSaved =>
      isEn ? 'Report saved to: ' : 'Laporan tersimpan di: ';
  String get receiptImageSaved =>
      isEn ? 'Receipt image saved' : 'Import gambar struk belanja tersimpan';

  // ── Dates ──
  List<String> get daysShort => isEn
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  List<String> get daysFull => isEn
      ? [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ]
      : ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  // ── General ──
  String get umum => isEn ? 'General' : 'Umum';
  String get transactionWord => isEn ? 'Transaction' : 'Transaksi';
  String todayLabel(String time) => isEn ? 'Today, $time' : 'Hari ini, $time';
  String yesterdayLabel(String time) =>
      isEn ? 'Yesterday, $time' : 'Kemarin, $time';
  String get yesterday => isEn ? 'yesterday' : 'kemarin';
  String daysAgo(int n) => isEn ? '$n days ago' : '$n hari lalu';
  String monthsAgo(int n) => isEn ? '$n months ago' : '$n bulan lalu';
}
