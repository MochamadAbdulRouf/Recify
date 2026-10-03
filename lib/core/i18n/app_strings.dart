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
  String insightTopCategory(String category, int percent, String period) =>
      isEn
          ? '$category takes $percent% of $period spending'
          : '$category menyerap $percent% pengeluaran $period';
  String get insightPeriodDaily => isEn ? 'the last 3 days’' : '3 hari terakhir';
  String get insightPeriodWeekly => isEn ? 'this week’s' : 'pekan ini';
  String get insightPeriodMonthly => isEn ? 'this month’s' : 'bulan ini';
  String get insightOnTrack => isEn
      ? 'Spending is within your usual pattern'
      : 'Pengeluaran masih dalam pola biasanya';
  String get exportTaxReport =>
      isEn ? 'Export Monthly Report' : 'Ekspor Laporan Bulanan';
  String get exportTaxReportHint =>
      isEn ? 'CSV ready for your records' : 'CSV siap untuk arsip Anda';
  String activeCount(int n) => isEn ? '$n active' : '$n aktif';
  String get tapBarHint =>
      isEn ? 'Tap a bar to see that period' : 'Ketuk batang untuk lihat periode itu';
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

  // ── Stats: Expense/Income Toggle ──
  String get expensesTab => isEn ? 'Expenses' : 'Pengeluaran';
  String get incomeTab => isEn ? 'Income' : 'Pemasukan';
  String get totalIncome => isEn ? 'Total Income' : 'Total Pemasukan';
  String get noIncome => isEn ? 'No income' : 'Tidak ada pemasukan';
  String get incomeCategoryBreakdown =>
      isEn ? 'Income by Category' : 'Rincian Kategori Pemasukan';
  String get noIncomeData =>
      isEn ? 'No income data yet' : 'Belum ada data pemasukan';
  String get noIncomeDataHint => isEn
      ? 'Record an income transaction to see visual stats.'
      : 'Catat transaksi pemasukan untuk melihat statistik visual.';
  String insightTopIncomeCategory(String category, int percent, String period) =>
      isEn
          ? '$category is $percent% of $period income'
          : '$category menyumbang $percent% pemasukan $period';

  List<String> get monthsShort => isEn
      ? const [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ]
      : const [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
        ];

  /// Label minggu berjalan pada sumbu grafik.
  String get thisWeekNow => isEn ? 'This week' : 'Minggu ini';

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

  // ── Export format dialog (reusable: Home, History, Stats) ──
  String get exportFormatTitle =>
      isEn ? 'Choose export format' : 'Pilih format ekspor';
  String get exportFormatExcel => isEn ? 'Excel (.xlsx)' : 'Excel (.xlsx)';
  String get exportFormatCsv => isEn ? 'CSV (.csv)' : 'CSV (.csv)';
  String get downloadAction => isEn ? 'Download' : 'Unduh';
  String get exportMonthLabel => isEn ? 'Month' : 'Bulan';
  String get exportYearLabel => isEn ? 'Year' : 'Tahun';
  String exportEmptyMonth(String monthYear) => isEn
      ? 'No data for $monthYear — pick another month.'
      : 'Tidak ada data untuk $monthYear — pilih bulan lain.';

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

  // ── Search (extends the History strings above) ──
  String get searchTitle => isEn ? 'Search' : 'Pencarian';
  String get searchEmptyTitle =>
      isEn ? 'No matching transaction' : 'Tidak ada transaksi cocok';
  String get searchEmptyHint => isEn
      ? 'Try another keyword, or a nominal like 50000'
      : 'Coba kata kunci lain, atau nominal seperti 50000';
  String get searchRecent => isEn ? 'Recent searches' : 'Pencarian terakhir';
  String get searchClearRecent => isEn ? 'Clear' : 'Hapus';
  String resultCount(int n) =>
      isEn ? '$n result${n == 1 ? '' : 's'}' : '$n hasil';

  // ── Notifications ──
  String get notificationsTitle => isEn ? 'Notifications' : 'Notifikasi';
  String get notificationsEmpty =>
      isEn ? 'Nothing needs your attention' : 'Tidak ada yang perlu ditindak';
  String get notificationsEmptyHint => isEn
      ? 'Budget alerts and unusual spending show up here'
      : 'Peringatan budget & pengeluaran tak wajar muncul di sini';
  String get markAllRead => isEn ? 'Mark all read' : 'Tandai semua dibaca';
  String get notifSectionAlert => isEn ? 'Needs attention' : 'Perlu tindakan';
  String get notifSectionInfo => isEn ? 'Insights' : 'Wawasan';
  String notifBudgetOver(String category, int percent) => isEn
      ? '$category is $percent% of budget'
      : '$category $percent% dari budget';
  String notifBudgetOverBody(String spent, String limit) => isEn
      ? 'Spent $spent of $limit this month'
      : 'Terpakai $spent dari $limit bulan ini';
  String notifBudgetNear(String category, int percent) => isEn
      ? '$category at $percent% of budget'
      : '$category sudah $percent% dari budget';
  String notifBudgetNearBody(String remaining) => isEn
      ? '$remaining left before the limit'
      : 'Sisa $remaining sebelum limit';
  String notifSpike(String category, int percent) => isEn
      ? '$category spending is up $percent%'
      : 'Pengeluaran $category naik $percent%';
  String notifSpikeBody(String avg) => isEn
      ? 'Above your 3-month average of $avg'
      : 'Di atas rata-rata 3 bulan Anda $avg';
  String notifUncategorized(int count) => isEn
      ? '$count transactions have no category'
      : '$count transaksi belum berkategori';
  String get notifUncategorizedBody => isEn
      ? 'Tap to categorize so reports stay accurate'
      : 'Ketuk untuk memberi kategori agar laporan akurat';

  // ── General ──
  String get umum => isEn ? 'General' : 'Umum';
  String get transactionWord => isEn ? 'Transaction' : 'Transaksi';
  String todayLabel(String time) => isEn ? 'Today, $time' : 'Hari ini, $time';
  String yesterdayLabel(String time) =>
      isEn ? 'Yesterday, $time' : 'Kemarin, $time';
  String get yesterday => isEn ? 'yesterday' : 'kemarin';
  String daysAgo(int n) => isEn ? '$n days ago' : '$n hari lalu';
  String monthsAgo(int n) => isEn ? '$n months ago' : '$n bulan lalu';

  // ── Settings / Account screen ──
  String get profileSettings =>
      isEn ? 'Profile & Settings' : 'Profil & Pengaturan';
  String get accountSecuritySubtitle => isEn
      ? 'Local Account Preferences & Security'
      : 'Preferensi & Keamanan Akun Lokal';
  String get offlineNote => isEn
      ? 'Local SQLite Storage • Optional AI'
      : 'Penyimpanan SQLite Lokal • AI Opsional';
  String get sectionAccountSecurity =>
      isEn ? 'ACCOUNT & SECURITY' : 'AKUN & KEAMANAN';
  String get sectionDataManager => isEn ? 'DATA MANAGEMENT' : 'MANAJEMEN DATA';
  String get sectionPrefsDisplay =>
      isEn ? 'PREFERENCES & DISPLAY' : 'PREFERENSI & TAMPILAN';
  String get sectionPrefs => isEn ? 'PREFERENCES' : 'PREFERENSI';
  String get sectionHelpInfo =>
      isEn ? 'HELP & INFORMATION' : 'BANTUAN & INFORMASI';

  String get manageWallets => isEn ? 'Wallets & Accounts' : 'Kelola Dompet & Akun';
  String walletCountSubtitle(int n) => isEn
      ? '$n Wallet${n == 1 ? '' : 's'} • Edit Balance & Add'
      : '$n Dompet • Edit Saldo & Tambah';
  String get securityData => isEn ? 'Data Security' : 'Keamanan Data';
  String get onDeviceProtection =>
      isEn ? 'On-Device Protection' : 'Proteksi On-Device';
  String get activeStatus => isEn ? 'Active' : 'Aktif';
  String get mainCurrency => isEn ? 'Primary Currency' : 'Mata Uang Utama';
  String get rupiahFormat =>
      isEn ? 'Indonesian Rupiah Format' : 'Format Rupiah Indonesia';
  String get idrFormat => 'IDR (Rp)';

  String get localBackupRestore =>
      isEn ? 'Local Backup & Restore' : 'Cadangan & Pemulihan Lokal';
  String get localBackupSubtitle => isEn
      ? 'Backup & restore SQLite database'
      : 'Backup & Restore database SQLite';
  String get exportTransactions =>
      isEn ? 'Export Transaction Data' : 'Ekspor Data Transaksi';
  String get exportTransactionsSubtitle => isEn
      ? 'Save to Download folder (Excel / CSV)'
      : 'Simpan ke folder Download (Excel / CSV)';
  String get clearImageCache =>
      isEn ? 'Clear Image Cache' : 'Bersihkan Cache Gambar';
  String get clearImageCacheSubtitle => isEn
      ? 'Delete temporary OCR scan files'
      : 'Hapus file temporary scan OCR';

  String get deepObsidianTheme =>
      isEn ? 'Deep Obsidian Dark Theme' : 'Tema Deep Obsidian Dark';
  String get deepObsidianSubtitle =>
      isEn ? 'Anti-glare OLED dark mode' : 'Mode Gelap OLED Anti-Silau';
  String get ledgerCategories =>
      isEn ? 'Ledger Categories' : 'Kategori Pembukuan';
  String categoryCountSubtitle(int n) => isEn
      ? '$n Categor${n == 1 ? 'y' : 'ies'} • Add & Manage'
      : '$n Kategori • Tambah & Kelola';
  String get monthlyBudget => isEn ? 'Monthly Budget' : 'Budget Bulanan';

  String get geminiAiParser => isEn ? 'Use AI Parser (Gemini)' : 'Gunakan AI Parser (Gemini)';
  String get geminiParserOn => isEn
      ? 'Parse receipts with Gemini AI'
      : 'Parsing struk menggunakan Gemini AI';
  String get geminiParserOff => isEn
      ? 'Parse receipts with offline regex'
      : 'Parsing struk menggunakan regex offline';
  String get apiKeyStored => isEn ? 'API key saved ✓' : 'API key tersimpan ✓';
  String get notConfigured => isEn ? 'Not configured' : 'Belum dikonfigurasi';
  String get emptyStatus => isEn ? 'Empty' : 'Kosong';

  String get helpCenter =>
      isEn ? 'Help Center & Guide' : 'Pusat Bantuan & Panduan';
  String get helpCenterSubtitle => isEn
      ? 'Scan receipts, auto recap & reports'
      : 'Scan struk, rekap otomatis & laporan';
  String get guideTitle => isEn ? 'Recify Guide' : 'Panduan Recify';
  String get guideBody => isEn
      ? '1. Tap the camera button in the middle of the bottom menu to scan a receipt.\n'
          '2. Make sure the receipt is flat and the text is clearly readable.\n'
          '3. Verify the total & save to your local SQLite database. If Gemini AI is on, the OCR text is sent to Google for analysis.\n'
          '4. Export accounting reports to Excel/CSV straight to the Download folder.'
      : '1. Buka tombol kamera di tengah menu bawah untuk scan struk belanja.\n'
          '2. Pastikan nota rata dan tulisan terbaca jelas.\n'
          '3. Verifikasi total & simpan ke database SQLite lokal Anda. Bila AI Gemini aktif, teks OCR dikirim ke Google untuk dianalisis.\n'
          '4. Ekspor laporan pembukuan ke format Excel/CSV langsung di folder Download.';
  String get understood => isEn ? 'Got it' : 'Mengerti';
  String get closeButton => isEn ? 'Close' : 'Tutup';
  String get privacyPolicy => isEn ? 'Privacy Policy' : 'Kebijakan Privasi';
  String get privacySubtitle =>
      isEn ? 'On-device first • Optional AI' : 'Lokal dulu • AI opsional';
  String get privacyBody => isEn
      ? 'Transactions, wallets & settings stay local (SQLite). If you enable the Gemini AI Parser and add an API key, OCR text is sent to Google and subject to Google’s privacy policy. Without a key, everything is 100% offline.'
      : 'Transaksi, dompet & pengaturan tersimpan lokal (SQLite). Bila Anda mengaktifkan AI Parser (Gemini) dan memasukkan API key, teks hasil OCR dikirim ke Google dan tunduk pada kebijakan privasi Google. Tanpa key, semua 100% offline.';
  String get versionLabel => isEn
      ? 'Recify Version 1.0.0 (Build 2026)'
      : 'Recify Versi 1.0.0 (Build 2026)';

  String get editUserProfile =>
      isEn ? 'Edit User Profile' : 'Edit Profil Pengguna';
  String get camera => isEn ? 'Camera' : 'Kamera';
  String get gallery => isEn ? 'Gallery' : 'Galeri';
  String get usernameField => isEn ? 'USERNAME' : 'NAMA PENGGUNA';
  String get usernameHint =>
      isEn ? 'Enter your name...' : 'Masukkan nama Anda...';
  String get saveChanges => isEn ? 'Save Changes' : 'Simpan Perubahan';

  String get add => isEn ? 'Add' : 'Tambah';
  String get editBalance => isEn ? 'Edit Balance' : 'Edit Saldo';
  String get editWallet => isEn ? 'Edit Wallet' : 'Edit Dompet';
  String get walletName => isEn ? 'Wallet Name' : 'Nama Dompet';
  String get currentBalanceLabel =>
      isEn ? 'Current Balance (Rp)' : 'Saldo Saat Ini (Rp)';
  String get save => isEn ? 'Save' : 'Simpan';
  String get apiKeyHelp => isEn
      ? 'Get a free API key at aistudio.google.com. The key is stored locally on your device and is never sent to any server other than Google AI.'
      : 'Dapatkan API key gratis di aistudio.google.com. Key disimpan lokal di perangkat, tidak dikirim ke server manapun selain Google AI.';
  String get addWalletTitle => isEn ? 'New Wallet' : 'Tambah Dompet Baru';
  String get walletNameField =>
      isEn ? 'Wallet / Account Name' : 'Nama Dompet / Akun';
  String get walletNameHint => isEn
      ? 'e.g. BCA, GoPay, Cash Wallet'
      : 'Contoh: BCA, GoPay, Dompet Tunai';
  String get accountType => isEn ? 'Account Type' : 'Tipe Akun';
  String get initialBalanceLabel =>
      isEn ? 'Initial Balance (Rp)' : 'Saldo Awal (Rp)';

  // Delete wallet (Poin 1)
  String get hapus => isEn ? 'Delete' : 'Hapus';
  String get deleteWalletConfirmTitle => isEn ? 'Delete Wallet?' : 'Hapus Dompet?';
  String deleteWalletBody(String name) => isEn
      ? 'Wallet "$name" will be removed permanently. A wallet that still contains transactions cannot be deleted.'
      : 'Dompet "$name" akan dihapus permanen. Dompet yang masih berisi transaksi tidak bisa dihapus.';
  String get deleteWalletLastGuard => isEn
      ? 'The last wallet cannot be deleted'
      : 'Dompet terakhir tidak bisa dihapus';
  String get deleteWalletInUse => isEn
      ? 'Wallet still contains transactions and cannot be deleted.'
      : 'Dompet masih berisi transaksi dan tidak bisa dihapus.';
  String deleteWalletSuccess(String name) => isEn
      ? 'Wallet "$name" deleted'
      : 'Dompet "$name" berhasil dihapus!';
  String deleteWalletFailed(String e) =>
      isEn ? 'Failed to delete wallet: $e' : 'Gagal menghapus dompet: $e';

  String get backupSectionTitle =>
      isEn ? 'Data Backup & Restore' : 'Cadangan & Pemulihan Data';
  String get backupSectionSubtitle => isEn
      ? 'Secure your financial database offline'
      : 'Amankan database keuangan Anda secara offline';
  String get createBackup => isEn ? 'Create New Backup' : 'Buat Cadangan Baru';
  String get createBackupSubtitle => isEn
      ? 'Save a JSON file to your phone Download folder'
      : 'Simpan file JSON ke folder Download HP';
  String get restoreBackup => isEn
      ? 'Restore from Backup File'
      : 'Pulihkan dari File Cadangan';
  String get restoreBackupSubtitle => isEn
      ? 'Pick from the backup files found'
      : 'Pilih dari file cadangan yang ditemukan';
  String get chooseBackupFile =>
      isEn ? 'Choose Backup File' : 'Pilih File Cadangan';
  String backupsFound(int n) => isEn
      ? '$n backup file${n == 1 ? '' : 's'} found in the Download folder'
      : 'Ditemukan $n file cadangan di folder Download';
  String get noBackupYet =>
      isEn ? 'No Recify backup files yet' : 'Belum ada file cadangan Recify';
  String get noBackupHint => isEn
      ? 'Create a new backup first to save it to Download.'
      : 'Buat cadangan baru terlebih dahulu untuk menyimpannya ke Download.';

  String get exportSubtitle => isEn
      ? 'Pick a report file format to save to the Download folder'
      : 'Pilih format file laporan untuk disimpan ke folder Download';
  String get excelFormat => 'Microsoft Excel (.xlsx)';
  String get excelFormatDesc => isEn
      ? 'Neatly formatted table with colors & cell headers'
      : 'Tabel terformat rapi dengan warna & header sel';
  String get csvFormat => isEn ? 'CSV Format (.csv)' : 'Format CSV (.csv)';
  String get csvFormatDesc => isEn
      ? 'Compatible with all accounting apps'
      : 'Kompatibel dengan semua aplikasi pembukuan';
  String get downloadToFolder =>
      isEn ? 'Download to Download Folder' : 'Unduh ke Folder Download';

  String get createCategory => isEn ? 'Create Category' : 'Buat Kategori';
  String get createCategoryTitle =>
      isEn ? 'Create New Category' : 'Buat Kategori Baru';
  String get categoryName => isEn ? 'Category Name' : 'Nama Kategori';
  String get categoryNameHint => isEn
      ? 'e.g. Streaming, Hobbies, Donations'
      : 'Contoh: Streaming, Hobi, Donasi';
  String get transactionType =>
      isEn ? 'Transaction Type' : 'Tipe Transaksi';
  String categoryAdded(String name) => isEn
      ? 'Category "$name" added!'
      : 'Kategori "$name" berhasil ditambahkan!';

  String get noLimitYet => isEn
      ? 'No limit • Set per category'
      : 'Belum ada limit • Atur per kategori';
  String budgetSummary(int set, String spent, String limit) => isEn
      ? '$set categories • $spent / $limit'
      : '$set kategori • $spent / $limit';
  String get budgetHint => isEn
      ? 'Tap a category to set or change its monthly limit'
      : 'Ketuk kategori untuk atur atau ubah limit bulanan';
  String get noExpenseCategories => isEn
      ? 'No expense categories yet'
      : 'Belum ada kategori pengeluaran';
  String spentLabel(String amount) =>
      isEn ? 'Used: $amount' : 'Terpakai: $amount';
  String get setLimit => isEn ? 'Set Limit' : 'Atur Limit';
  String limitTitle(String name) =>
      isEn ? 'Limit for $name' : 'Limit $name';
  String get monthlyLimitField =>
      isEn ? 'Monthly Limit (Rp)' : 'Limit Bulanan (Rp)';
  String get limitHint => isEn ? 'e.g. 1,500,000' : 'Contoh: 1.500.000';
  String limitDeleted(String name) =>
      isEn ? 'Limit $name deleted' : 'Limit $name dihapus';
  String limitSaved(String name, String value) =>
      isEn ? 'Limit $name: $value' : 'Limit $name: $value';

  // ── Settings snackbars ──
  String get cacheCleared => isEn
      ? 'Temporary cache cleared!'
      : 'Cache sementara berhasil dibersihkan!';
  String cacheFailed(String e) =>
      isEn ? 'Failed to clear cache: $e' : 'Gagal membersihkan cache: $e';
  String get profileSaved => isEn ? 'Profile saved!' : 'Profil berhasil disimpan!';
  String get userNameDefault => isEn ? 'Recify User' : 'Pengguna Recify';

  // ── Toast ──
  String get toastSuccessTitle => isEn ? 'Success' : 'Berhasil';
  String get toastErrorTitle => isEn ? 'Failed' : 'Gagal';

  // ── Theme toggle ──
  String get themeSettings => isEn ? 'App Theme' : 'Tema Aplikasi';
  String get themeSystem => isEn ? 'System' : 'Sistem';
  String get themeLight => isEn ? 'Light' : 'Terang';
  String get themeDark => isEn ? 'Dark' : 'Gelap';
  String get themeSystemSubtitle => isEn
      ? 'Follows device setting'
      : 'Ikut pengaturan perangkat';
  String get themeLightSubtitle =>
      isEn ? 'Light theme' : 'Tema terang';
  String get themeDarkSubtitle =>
      isEn ? 'Dark theme' : 'Tema gelap';

  // ── Receipt date validation ──
  String get dateOldTitle =>
      isEn ? 'Receipt Date Is Old' : 'Tanggal Nota Sudah Lama';
  String useReceiptDate(String date) => isEn
      ? 'Use Receipt Date ($date)'
      : 'Pakai Tanggal Nota ($date)';
  String get dateUnreadableNotice => isEn
      ? 'Receipt date unreadable — using today'
      : 'Tanggal nota tidak terbaca — memakai hari ini';
  String get dateFutureNotice => isEn
      ? 'Receipt date is in the future — using today'
      : 'Tanggal nota di masa depan — memakai hari ini';
  String dateConfirmToday(String date) => isEn
      ? 'Use today ($date)?'
      : 'Yakin memakai tanggal hari ini ($date)?';
  String dateConfirmReceipt(String date) => isEn
      ? 'Use receipt date ($date)?'
      : 'Yakin memakai tanggal nota ($date)?';
  String get confirmUse => isEn ? 'Yes, use it' : 'Ya, gunakan';
  String get kembali => isEn ? 'Back' : 'Kembali';

  // ── Discard scan result ──
  String get discardScanTitle =>
      isEn ? 'Discard scan result?' : 'Buang hasil scan?';
  String get discardScanBody => isEn
      ? 'Scan result will be lost and not saved. Continue?'
      : 'Hasil scan akan hilang dan tidak tersimpan. Lanjutkan?';
  String get keepEditing => isEn ? 'Keep editing' : 'Tetap di sini';
  String get discardScan => isEn ? 'Discard' : 'Buang hasil';

  // ── Gemini quota ──
  String geminiQuotaExhausted(String model, String remaining) => isEn
      ? 'Free quota for $model exhausted, back in $remaining. Using offline parser for now.'
      : 'Kuota gratis $model habis, kembali dalam $remaining. Sementara memakai parser offline.';
  String get geminiModel => isEn ? 'Gemini Model' : 'Model Gemini';
  String geminiKeysSubtitle(int n) => isEn
      ? '$n key${n == 1 ? '' : 's'} • tap to manage'
      : '$n kunci • ketuk untuk kelola';
  String get geminiKeysTitle => isEn ? 'Gemini API Keys' : 'Kunci API Gemini';
  String get addKey => isEn ? 'Add key' : 'Tambah kunci';
  String get keyActive => isEn ? 'Active' : 'Aktif';
  String quotaAvailableIn(String t) => isEn
      ? 'available in $t'
      : 'tersedia $t';
  String get pasteKeyHint => 'AIza...';
  String get keyAdded => isEn ? 'API key added' : 'Kunci API ditambahkan';
  String get keyRemoved => isEn ? 'API key removed' : 'Kunci API dihapus';
  String get keyDeleteBody => isEn
      ? 'Remove this API key from the list?'
      : 'Hapus kunci API ini dari daftar?';
  String get keyDeleteActiveBody => isEn
      ? 'This is the active key. Remove it and switch to another key?'
      : 'Ini kunci yang sedang aktif. Hapus dan pindah ke kunci lain?';

  // ── OCR Scanner Verification v2 (Stitch) ──
  String get scanAndPay => 'Scan & Pay';
  String get ocrActiveDevice => 'OCR ACTIVE • ON-DEVICE';
  String get hundredPrivate => '100% PRIVATE';
  String get taxIncluded => isEn ? 'Tax included' : 'Termasuk pajak';
  String get change => isEn ? 'Change' : 'Ubah';
  String get confirmAndSave => isEn ? 'Confirm & Save' : 'Konfirmasi & Simpan';
  String get autoMapped => isEn ? 'Auto-mapped' : 'Otomatis';
  String get encryptedBadge => isEn
      ? 'Data encrypted locally using AES-256-GCM hardware encryption'
      : 'Data dienkripsi lokal dengan enkripsi perangkat AES-256-GCM';
  String walletUpdated(String name) => isEn
      ? 'Wallet "$name" updated!'
      : 'Dompet "$name" berhasil diperbarui!';
  String apiKeySavedMsg(int n) => isEn
      ? 'API key saved! $n characters.'
      : 'API Key berhasil disimpan! $n karakter.';
  String walletAdded(String name) => isEn
      ? 'Wallet "$name" added!'
      : 'Dompet "$name" berhasil ditambahkan!';
  String backupSaved(String path) => isEn
      ? 'Backup saved at: $path'
      : 'Cadangan tersimpan di: $path';
  String backupFailed(String e) =>
      isEn ? 'Backup failed: $e' : 'Gagal backup: $e';
  String get restoreDone => isEn
      ? 'Data restored from backup!'
      : 'Data berhasil dipulihkan dari cadangan!';
  String restoreFailed(String e) =>
      isEn ? 'Failed to restore: $e' : 'Gagal memulihkan: $e';
  String exportDone(String path) => isEn
      ? 'Report exported to: $path'
      : 'Laporan berhasil diekspor ke: $path';
  String exportTransactionsFailed(String e) => isEn
      ? 'Export failed: $e'
      : 'Gagal mengekspor: $e';
}
