# Recify — Smart Offline-First Expense Tracker & Receipt OCR

<p align="center">
  <b>Aplikasi pelacak keuangan pribadi multi-akun & pemindai struk belanja cerdas berbasis 100% On-Device AI OCR (Google ML Kit). Tanpa cloud, tanpa login online, dan privasi penuh.</b>
</p>

---

## ✨ Fitur Utama

- 📸 **On-Device Receipt OCR (Offline AI)** — Pindai struk belanja toko (Indomaret, Alfamart, restoran, dll.) secara instan langsung di HP dengan Google ML Kit; OCR 100% on-device. Pemecahan rinci per-item dan validasi diperkaya Gemini (opsional, butuh koneksi internet + API key, lihat Prasyarat).
- 🔐 **Auth Lokal Multi-User** — Daftar & login sepenuhnya tanpa server; password disimpan sebagai salted hash, dan seluruh data (dompet, kategori, transaksi, budget) terisolasi per akun.
- 💱 **Multi-Currency + Kurs Realtime** — Catat transaksi dalam 15 mata uang (IDR, USD, EUR, JPY, SGD, dst.) lengkap dengan emoji bendera. Kurs diambil realtime dari [open.er-api.com](https://open.er-api.com), di-cache per hari (tetap tampil saat offline), dan semua saldo konsolidasi dalam IDR.
- 🏦 **Multi-Dompet** — Kelola dana tunai, rekening bank, dan e-wallet dengan saldo gabungan di hero card serta pengalih dompet cepat (account switch sheet).
- 🎯 **Anggaran (Budget) Bulanan per Kategori** — Tetapkan batas belanja per kategori tiap bulan dan pantau progres serta sisa anggaran lewat progress bar.
- 🔔 **Notifikasi Lokal Transaksi** — Notifikasi Android muncul segera setiap pengeluaran/pemasukan tersimpan; tap notifikasi langsung membuka detail transaksinya (notification center + deep-link routing, tetap bekerja setelah app di-cold start).
- 💾 **Backup & Restore JSON** — Ekspor seluruh data akun ke folder Download sebagai `Recify_Backup_*.json`, lalu pulihkan kembali kapan saja dari dalam app.
- 📊 **Statistik & Analisis Keuangan** — Grafik pengeluaran per kategori, arus kas periodik, tren, dan insight kategori yang menghitung agregat per periode.
- 🔍 **Pencarian Global** — Cari transaksi lintas dompet dan kategori dari satu layar pencarian.
- ✍️ **Pencatatan Transaksi Manual Cerdas**:
  - Pemisah ribuan otomatis (tanda titik `.`) saat mengetik nominal.
  - Carousel kategori horizontal yang fleksibel dan interaktif.
  - Pembedaan warna otomatis (Merah untuk Pengeluaran, Hijau untuk Pemasukan).
- 🌐 **Bilingual ID/EN** — Seluruh UI dan copy notifikasi tersedia dalam Bahasa Indonesia dan English (data transaksi pengguna tidak pernah diterjemahkan — tetap apa adanya).
- 🌗 **Mode Tema System / Light / Dark** — *Obsidian Flux* gelap tetap identitas utama; palet light disusun manual agar tetap berkarakter, bukan sekadar inversi mekanis.
- 📁 **Ekspor Laporan CSV & Excel (.xlsx)** — Pilih format lewat dialog dan simpan rekapitulasi transaksi (per bulan/log penuh) ke folder Download.
- 🔒 **Zero-Cloud Privacy** — Semua data transaksi, kategori, dompet, budget, foto struk, dan API key Gemini tersimpan aman di database lokal SQLite perangkat Anda.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework**: [Flutter](https://flutter.dev) (Dart ^3.10)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Auth Lokal**: Salted password hash + repositori user SQLite (tanpa backend)
- **On-Device Vision/OCR**: [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- **AI Receipt Parsing**: [google_generative_ai](https://pub.dev/packages/google_generative_ai) (Gemini)
- **Kurs Realtime**: [open.er-api.com](https://open.er-api.com) via [http](https://pub.dev/packages/http), cache harian di [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Notifikasi Lokal**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Local Export**: [csv](https://pub.dev/packages/csv) & [excel](https://pub.dev/packages/excel)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Typography**: [Google Fonts (Plus Jakarta Sans)](https://pub.dev/packages/google_fonts)
- **Image Processing**: [image](https://pub.dev/packages/image), [image_picker](https://pub.dev/packages/image_picker)

---

## 🚀 Memulai (Getting Started)

### Prasyarat:
- Flutter SDK (v3.38.1 atau lebih baru — dipresyaratkan `flutter_local_notifications` 22.x)
- Android SDK & JDK 17
- Perangkat fisik Android atau Emulator Android (**minSdk 24 / Android 7.0+**)
- *(Opsional)* API key Gemini dari [aistudio.google.com](https://aistudio.google.com/app/apikey), masukkan di dalam app: Settings → Gemini API Keys

### Langkah Instalasi:

1. **Clone repository:**
   ```bash
   git clone https://github.com/MochamadAbdulRouf/Recify.git
   cd Recify
   ```

2. **Install dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat:**
   ```bash
   flutter run
   ```

4. **Buat akun lokal pertama (mendaftar):**
   Isi nama, email, dan password — tanpa koneksi ke mana pun. Kredensial ditampakkan 5 detik sebagai konfirmasi, sisanya langsung bisa dipakai.

5. **Build APK rilis:**
   ```bash
   flutter build apk --release
   ```
   Hasil build tersedia di `build/app/outputs/flutter-apk/app-release.apk` (folder `dist/` dipakai sebagai staging artefak rilis dan diabaikan git).

### Menjalankan Tes:

```bash
flutter test
```

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── constants/        # Daftar 15 mata uang didukung (currencies.dart)
│   ├── i18n/             # AppStrings bilingual ID/EN
│   ├── services/         # ExchangeRateService (kurs realtime + cache), ProfileService
│   ├── theme/            # Obsidian Flux: AppColors (light/dark), AppMotion, AppTheme, AppTypography
│   └── utils/            # CurrencyFormatter, PeriodAggregator, TrendCalculator, TransactionFilter, PasswordHasher, dll.
├── data/
│   ├── local/            # SQLite DatabaseHelper (tabel budget & indeks periode) + SeedData
│   ├── models/           # Transaction (+ item), Category, Wallet, Budget, User, ParsedReceipt
│   └── repositories/     # FinanceRepository, AuthRepository (salted hash), ReceiptArchiveManager
├── domain/
│   ├── backup/           # BackupManager (ekspor JSON → Download & restore)
│   ├── export/           # ReportExporter (generator CSV & Excel)
│   ├── notifications/    # NotificationBuilder
│   └── ocr/              # MLKitReceiptScanner, IndonesianReceiptParser, GeminiReceiptParser, ReceiptValidator
├── presentation/
│   ├── components/       # FloatingIslandNavBar (responsif), ObsidianHeroCard, QuickActionGrid, BudgetProgressBar, StickyFrostedAppBar, dll.
│   ├── providers/        # Finance, Scanner, Auth, Theme, Locale, ExchangeRate Provider
│   ├── screens/          # AuthGate/Login/Signup/Credentials, Dashboard, ManualTransaction, QuickVerification, History/Detail Transaksi, GlobalSearch, Analytics, NotificationCenter, Settings
│   ├── services/         # TransactionNotificationService & NotificationRouter
│   └── widgets/          # CurrencyPickerField, WalletPickerField
└── main.dart             # Entrypoint aplikasi Flutter
```

---

## 📄 Lisensi
Hak Cipta © 2026 **Recify**. Dilisensikan di bawah [MIT License](LICENSE).
