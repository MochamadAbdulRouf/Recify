# Recify — Smart Offline-First Expense Tracker & Receipt OCR

<p align="center">
  <b>Aplikasi pelacak keuangan pribadi & pemindai struk belanja cerdas berbasis 100% On-Device AI OCR (Google ML Kit). Tanpa cloud, tanpa login, dan privasi penuh.</b>
</p>

---

## ✨ Fitur Utama

- 📸 **On-Device Receipt OCR (Offline AI)**: Pindai struk belanja toko (Indomaret, Alfamart, restoran, dll.) secara instan langsung di HP menggunakan Google ML Kit tanpa perlu koneksi internet.
- 💳 **Obsidian Flux Dark Design System**: Antarmuka modern dengan palet warna OLED (*Deep Matte Obsidian*), tipografi *Plus Jakarta Sans*, dan micro-interactions yang halus.
- 🏝️ **Floating Island Navigation**: Navigasi pulau melayang dengan efek frosted glass dan tombol kamera elevated.
- 📊 **Statistik & Analisis Keuangan**: Visualisasi pengeluaran riil per kategori dan arus kas bulanan secara dinamis.
- ✍️ **Pencatatan Transaksi Manual Cerdas**:
  - Pemisah ribuan otomatis (tanda titik `.`) saat mengetik nominal rupiah.
  - Carousel kategori horizontal yang fleksibel dan interaktif.
  - Pembedaan warna otomatis (Merah untuk Pengeluaran, Hijau untuk Pemasukan).
- 📁 **Ekspor Laporan CSV Lokal**: Simpan dan bagikan rekapitulasi data transaksi ke format Excel/CSV kapan saja.
- 🔒 **Zero-Cloud Privacy**: Semua data transaksi, kategori, dompet, dan foto struk tersimpan aman di database lokal SQLite perangkat Anda.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **On-Device Vision/OCR**: [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- **Typography**: [Google Fonts (Plus Jakarta Sans)](https://pub.dev/packages/google_fonts)
- **Image Processing**: [image](https://pub.dev/packages/image), [image_picker](https://pub.dev/packages/image_picker)

---

## 🚀 Memulai (Getting Started)

### Prasyarat:
- Flutter SDK (v3.20.0 atau lebih baru)
- Android SDK & JDK 17
- Perangkat fisik Android atau Emulator Android (minSdk 21 / Android 5.0+)

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

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── theme/           # Obsidian Flux theme tokens, AppColors, AppTypography
│   └── utils/           # CurrencyFormatter, DateFormatter, CurrencyInputFormatter
├── data/
│   ├── database/        # SQLite DatabaseHelper & skema tabel lokal
│   ├── models/          # Transaction, Category, Wallet, ParsedReceipt models
│   └── repositories/    # FinanceRepository & ReceiptArchiveManager
├── domain/
│   ├── export/          # ReportExporter (CSV generator)
│   └── ocr/             # MLKitReceiptScanner & IndonesianReceiptParser
├── presentation/
│   ├── components/      # FloatingIslandNavBar, ObsidianHeroCard, QuickActionGrid
│   ├── providers/       # FinanceProvider & ScannerProvider
│   └── screens/         # HomeDashboard, QuickVerification, ManualTransaction, Analytics, Settings
└── main.dart            # Entrypoint aplikasi Flutter
```

---

## 📄 Lisensi
Hak Cipta © 2026 **Recify**. Dilisensikan di bawah [MIT License](LICENSE).
