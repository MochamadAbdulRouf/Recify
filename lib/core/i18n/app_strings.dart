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
  String get appTagline => isEn ? 'Expense Tracker & Local OCR' : 'Pelacak Pengeluaran & OCR Lokal';
  String get totalBalance => isEn ? 'TOTAL BALANCE' : 'TOTAL SALDO';
  String get income => isEn ? 'Income' : 'Pemasukan';
  String get expense => isEn ? 'Expense' : 'Pengeluaran';
  String get recentActivity => isEn ? 'Recent Activity' : 'Aktivitas Terbaru';
  String get viewAll => isEn ? 'View All' : 'Lihat Semua';
  String get scanReceipt => isEn ? 'Scan Receipt' : 'Pindai Struk Belanja';
  String get scanReceiptSubtitle => isEn ? 'Local AI extraction of totals & items' : 'Ekstraksi total harga & item secara lokal (AI)';
  String get manualEntry => isEn ? 'Manual Entry' : 'Catat Manual';
  String get exportReport => isEn ? 'Export Report' : 'Ekspor Laporan';
  String get noTransactionsYet => isEn ? 'No transactions recorded' : 'Belum ada transaksi tercatat';
  String get noTransactionsHint => isEn ? 'Snap a receipt photo or record an expense' : 'Ambil foto nota atau catat pengeluaran Anda';
  String get startScan => isEn ? 'Start Scanning' : 'Mulai Scan Nota';

  // ── Hero card status ──
  String get walletActive => isEn ? 'Wallet Active' : 'Dompet Aktif';
  String get updated => isEn ? 'Updated' : 'Diperbarui';
  String get justNow => isEn ? 'just now' : 'baru saja';
  String get minutesAgoShort => isEn ? 'min ago' : 'mnt lalu';
  String get hoursAgoShort => isEn ? 'h ago' : 'jam lalu';
  String get noDataYet => isEn ? 'no data yet' : 'belum ada data';

  // ── Scan sheet ──
  String get chooseSource => isEn ? 'Choose Receipt Source' : 'Pilih Sumber Foto Nota';
  String get cameraOption => isEn ? 'Take Photo' : 'Ambil Foto Kamera';
  String get cameraOptionHint => isEn ? 'Scan receipt instantly with on-device OCR' : 'Scan nota langsung dengan OCR on-device';
  String get galleryOption => isEn ? 'Pick from Gallery' : 'Pilih dari Galeri';
  String get galleryOptionHint => isEn ? 'Pick a receipt image from your gallery' : 'Pilih gambar nota dari galeri';
  String get scanTargetHint => isEn ? 'Point the camera at your receipt' : 'Arahkan kamera ke struk belanja';
  String get instantOcrHint => isEn ? 'Instant on-device OCR extraction' : 'Ekstraksi OCR otomatis secara instan di HP Anda';
  String get scanReceiptNav => isEn ? 'Scan Receipt' : 'Pindai Struk / Nota';

  // ── Stats ──
  String get statsTitle => isEn ? 'Statistics & Analysis' : 'Statistik & Analisis';
  String get statsSubtitle => isEn ? 'Spending & Cash Flow Report' : 'Laporan Pengeluaran & Arus Kas';
  String get daily => isEn ? 'Daily' : 'Harian';
  String get weekly => isEn ? 'Weekly' : 'Mingguan';
  String get monthly => isEn ? 'Monthly' : 'Bulanan';
  String get totalSpending => isEn ? 'Total Spending' : 'Total Pengeluaran';
  String get noSpending => isEn ? 'No spending' : 'Tidak ada pengeluaran';
  String get categoryBreakdown => isEn ? 'Spending by Category' : 'Rincian Kategori Pengeluaran';
  String get categoriesLabel => isEn ? 'Categories' : 'Kategori';
  String get transactionsLabel => isEn ? 'Transactions' : 'Transaksi';
  String get noSpendingData => isEn ? 'No spending data yet' : 'Belum ada data pengeluaran';
  String get noSpendingDataHint => isEn ? 'Record a transaction or scan a receipt to see visual stats.' : 'Catat transaksi atau pindai struk untuk melihat statistik visual.';

  // ── History ──
  String get historyTitle => isEn ? 'Transaction History' : 'Riwayat Transaksi';
  String historyCount(int n) => isEn ? '$n transactions recorded' : '$n transaksi tercatat';
  String get searchHint => isEn ? 'Search transactions, merchants, notes…' : 'Cari transaksi, merchant, catatan…';
  String get filterAll => isEn ? 'All' : 'Semua';
  String get filterExpense => isEn ? 'Expense' : 'Pengeluaran';
  String get filterIncome => isEn ? 'Income' : 'Pemasukan';
  String get exportCsv => isEn ? 'Export CSV' : 'Ekspor CSV';
  String get emptyHistoryTitle => isEn ? 'No transactions found' : 'Tidak ada transaksi ditemukan';
  String get emptyHistoryHint => isEn ? 'Try different keywords or filters' : 'Coba ubah kata kunci pencarian atau filter';

  // ── Settings ──
  String get settingsTitle => isEn ? 'Settings' : 'Pengaturan';
  String get language => isEn ? 'Language' : 'Bahasa';
  String get languageSubtitle => isEn ? 'Switch app language' : 'Ganti bahasa aplikasi';
  String get english => isEn ? 'English' : 'Inggris';
  String get indonesian => isEn ? 'Indonesian' : 'Indonesia';

  // ── Common ──
  String get exportFailed => isEn ? 'Export failed: ' : 'Gagal ekspor: ';
  String get reportSaved => isEn ? 'Report saved to: ' : 'Laporan tersimpan di: ';
  String get receiptImageSaved => isEn ? 'Receipt image saved' : 'Import gambar struk belanja tersimpan';

  // ── Dates ──
  List<String> get daysShort => isEn
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  List<String> get daysFull => isEn
      ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
      : ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  // ── General ──
  String get umum => isEn ? 'General' : 'Umum';
  String get transactionWord => isEn ? 'Transaction' : 'Transaksi';
  String todayLabel(String time) => isEn ? 'Today, $time' : 'Hari ini, $time';
  String yesterdayLabel(String time) => isEn ? 'Yesterday, $time' : 'Kemarin, $time';
}
