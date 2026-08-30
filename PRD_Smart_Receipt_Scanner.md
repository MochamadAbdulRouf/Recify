# Product Requirement Document (PRD)

**Product Name:** Smart Receipt Scanner (Offline-First / Local Storage)  
**Document Version:** 1.0.0  
**Target Release:** Q4 2026  
**Status:** Ready for Review / Engineering Hand-off  
**Author:** Product & Architecture Team  

---

## 1. Executive Summary & Problem Statement

### 1.1 Executive Summary
**Smart Receipt Scanner** adalah aplikasi mobile pencatat keuangan pribadi berbasis *offline-first* yang memanfaatkan pemrosesan OCR *on-device* untuk mengekstrak data struk belanja secara otomatis dan instan tanpa membutuhkan koneksi internet atau server pihak ketiga (*zero cloud dependencies*). Seluruh data transaksi, rincian nota belanja (*itemized data*), dan arsip foto nota disimpan secara lokal dan aman di perangkat pengguna menggunakan SQLite dan direktori file internal.

### 1.2 Problem Statement
1. **Tingginya Friksi Input Manual:** Pengguna seringkali menunda atau malas mencatat pengeluaran harian karena proses pengetikan manual (nama merchant, tanggal, nominal, dan rincian item) memakan waktu 30–60 detik per transaksi.
2. **Kekhawatiran Privasi & Ketergantungan Internet:** Sebagian besar aplikasi pencatat keuangan dan scanner nota di pasar mewajibkan akun cloud dan mengirim foto nota ke server eksternal, menimbulkan risiko privasi data finansial serta kegagalan sistem di area dengan sinyal lemah.
3. **Pencatatan Global vs. Itemized:** Pengeluaran di minimarket/supermarket sering kali hanya dicatat sebagai satu nominal global tanpa rincian barang, menyulitkan audit pengeluaran mendalam dan alokasi multi-kategori.

### 1.3 Product Goals & Objectives
* Mengurangi durasi pencatatan transaksi dari rata-rata 45 detik (manual) menjadi $\le 5$ detik via scan OCR lokal.
* Menjamin privasi data finansial 100% tetap berada di perangkat lokal (*zero network telemetry/cloud storage*).
* Menghadirkan performa antarmuka yang cepat dan responsif (waktu respon $\le 16\text{ms}$ / 60 FPS) meski menyimpan puluhan ribu data transaksi lokal.

---

## 2. Target User & Use Cases

### 2.1 User Personas

| Persona | Profil & Karakteristik | Kebutuhan Utama | Pain Point |
| :--- | :--- | :--- | :--- |
| **Budget-Conscious Shopper** | Individu yang rutin berbelanja kebutuhan pokok di minimarket/supermarket. | Ingin mencatat nota belanja panjang dengan cepat tanpa input satu per satu. | Lelah mengetik puluhan baris item belanja dari struk fisik. |
| **Privacy-Focused Individual** | Pengguna yang sadar keamanan data dan menolak sinkronisasi cloud finansial. | Aplikasi tanpa login/registrasi, berjalan 100% offline di perangkat. | Khawatir data kebiasaan belanja di-monetisasi atau bocor. |
| **Freelancer / UMKM Owner** | Pekerja lepas / pemilik bisnis mikro yang butuh rekap pengeluaran operasional. | Arsip digital bukti nota fisik dan ekspor laporan ke Excel/CSV. | Kertas nota thermal cepat pudar/hilang sebelum waktu pembukuan. |

---

## 3. Product Scope & Functional Requirements

### Modul 1: On-Device OCR & Data Extraction (Core Engine)

| ID | Fitur | Prioritas | Deskripsi & Acceptance Criteria |
| :--- | :--- | :---: | :--- |
| **FR-01** | **Local Receipt Capture** | **P0** | Pengguna dapat mengambil foto nota langsung melalui kamera in-app atau memilih gambar dari galeri lokal tanpa transmisi data keluar. |
| **FR-02** | **Image Pre-processing** | **P0** | Sistem secara otomatis menerapkan *auto-crop* sudut nota, koreksi perspektif (*dewarping*), dan filter kontras/grayscale untuk mempertajam teks pada nota termal yang pudar. |
| **FR-03** | **Local OCR Text Extraction** | **P0** | Ekstraksi teks berbasis Google ML Kit On-Device yang menghasilkan raw text berserta koordinat bounding box tanpa latensi jaringan. |
| **FR-04** | **Rule-Based Regex Parsing** | **P0** | Parser lokal mengekstrak entitas penting: Nama Merchant, Tanggal/Waktu, Itemized List (Nama, Qty, Harga Satuan, Total), Pajak, Diskon, dan Grand Total ke format JSON terstruktur. |
| **FR-05** | **Quick Verification Screen** | **P0** | Antarmuka *split-screen* (bagian atas: preview foto nota, bagian bawah: form isian hasil parsing) untuk memvalidasi dan mengoreksi data dalam 2–3 detik sebelum disimpan. |
| **FR-06** | **Manual Fallback Input** | **P0** | Form entri manual lengkap untuk transaksi tunai tanpa struk atau nota fisik yang rusak total. |

---

### Modul 2: Manajemen Transaksi & Saldo Lokal

| ID | Fitur | Prioritas | Deskripsi & Acceptance Criteria |
| :--- | :--- | :---: | :--- |
| **FR-07** | **Multi-Wallet / Multi-Account** | **P0** | Mendukung pengelolaan multi-dompet terpisah (Tunai, Bank, E-Wallet, Kartu Kredit) dengan perhitungan saldo real-time. |
| **FR-08** | **Auto-Categorization** | **P0** | Pengkategorian otomatis berbasis kata kunci/regex lokal dari nama merchant atau rincian item (contoh: "Indomaret" $\rightarrow$ *Groceries*, "Pertamina" $\rightarrow$ *Transportasi*). |
| **FR-09** | **Itemized & Split Transaction** | **P1** | Satu nota belanja dapat dipecah ke beberapa kategori berbeda berdasarkan rincian item barang. |
| **FR-10** | **Recurring Transactions** | **P2** | Fitur template pengeluaran/pemasukan rutin (sewa, langganan, tagihan) dengan sistem pengingat lokal (*local notification*). |

---

### Modul 3: Budgeting, Analytics & Arsip Lokal

| ID | Fitur | Prioritas | Deskripsi & Acceptance Criteria |
| :--- | :--- | :---: | :--- |
| **FR-11** | **Category Budgeting** | **P0** | Menetapkan batas pengeluaran bulanan per kategori. |
| **FR-12** | **Instant Overspending Alert** | **P1** | Indikator visual progres anggaran pada dashboard (peringatan kuning pada 80% dan merah pada $\ge 100\%$). |
| **FR-13** | **Local Receipt Archive** | **P0** | File gambar nota dikompresi (JPEG 75%) dan disimpan di direktori privat aplikasi (`app_data/receipts/`), tertaut dengan ID transaksi dan dapat di-preview kapan saja. |
| **FR-14** | **Cash Flow & Visual Analytics** | **P1** | Grafik tren pengeluaran mingguan/bulanan, perbandingan *Income vs Expense*, dan diagram lingkaran komposisi kategori. |
| **FR-15** | **Local Backup & Export** | **P0** | Ekspor data riwayat transaksi ke format Excel (XLSX), CSV, dan ringkasan PDF. Fitur Backup/Restore berupa file dump database lokal (`.sqlite` / `.json`). |

---

### Modul 4: Keamanan & Preferensi

| ID | Fitur | Prioritas | Deskripsi & Acceptance Criteria |
| :--- | :--- | :---: | :--- |
| **FR-16** | **App Security Lock** | **P1** | Opsi penguncian aplikasi menggunakan PIN lokal atau Autentikasi Biometrik (Fingerprint / Face ID). |
| **FR-17** | **Customization** | **P0** | Pengguna dapat mengelola daftar kategori (nama, ikon, warna) dan dompet kustom. |

---

## 4. On-Device Receipt Processing Pipeline

Seluruh pemrosesan berjalan di sisi klien (*client-side*) tanpa memakan kuota internet:

```
[1. Ambil Foto Nota via Kamera / Galeri]
       │
       ▼ (Kompresi & Filter Kontras Lokal)
[2. Pre-processing Gambar]
       │
       ▼ (Google ML Kit On-Device Text Recognition)
[3. Ekstraksi Raw Text & Koordinat Baris]
       │
       ▼ (Local Regex Parser & Rule-Based Matcher)
[4. Output JSON Terstruktur]
       │
       ▼ (Review Cepat di Layar Verifikasi)
[5. Konfirmasi Pengguna]
       │
       ├──► [Simpan File Gambar ke Direktori Internal: app_data/receipts/*.jpg]
       └──► [Insert Data Transaksi ke Database SQLite Lokal]
```

---

## 5. End-to-End App Navigation Flow

```
[Splash Screen]
       │
       ▼
[Dashboard Utama]
├── Saldo Total & Ringkasan Per Dompet
├── Indikator Penggunaan Budget Bulanan
├── Grafik Arus Kas Singkat
├── Daftar Transaksi Terbaru
│
├──► [Floating Action Button (+)]
│         ├──► [Scan Nota (Kamera OCR)] ──► [Parsing Otomatis] ──► [Verifikasi Data] ──► [Simpan Transaksi]
│         ├──► [Input Pengeluaran Manual] ───────────────────────► [Form Input] ──────► [Simpan Transaksi]
│         └──► [Catat Pemasukan] ────────────────────────────────► [Form Income] ─────► [Simpan Transaksi]
│
├──► [Tab Riwayat & Pencarian]
│         ├── Filter Tanggal / Kategori / Dompet
│         ├── Pencarian Transaksi berdasarkan Nama Merchant / Item
│         └── Detail Transaksi + Preview Foto Nota Lokal
│
├──► [Tab Anggaran / Budgeting]
│         ├── Progress Bar Anggaran per Kategori
│         └── Setup Limit Anggaran Bulanan
│
├──► [Tab Laporan & Analitik]
│         ├── Grafik Arus Kas Lengkap & Diagram Kategori
│         └── Ekspor Laporan (Excel / CSV / PDF)
│
└──► [Tab Pengaturan]
          ├── Manajemen Akun / Dompet
          ├── Kustomisasi Kategori
          ├── Keamanan (PIN / Biometrik Lokal)
          └── Backup & Restore Data Lokal (JSON / SQLite Dump)
```

---

## 6. Skema Database Relasional (SQLite)

Berikut adalah struktur DDL database lokal SQLite yang dioptimalkan dengan indexing:

```sql
-- 1. Tabel Manajemen Dompet / Akun
CREATE TABLE wallets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL, -- Contoh: "Dompet Tunai", "BCA", "GoPay"
    type TEXT NOT NULL, -- 'CASH', 'BANK', 'E_WALLET', 'CREDIT'
    initial_balance REAL DEFAULT 0,
    current_balance REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Kategori Pengeluaran & Pemasukan
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL, -- Contoh: "Groceries", "Makan & Minum", "Transportasi"
    type TEXT NOT NULL, -- 'EXPENSE', 'INCOME'
    icon TEXT,
    color TEXT
);

-- 3. Tabel Target Anggaran Bulanan
CREATE TABLE budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    monthly_limit REAL NOT NULL,
    month INTEGER NOT NULL, -- 1-12
    year INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- 4. Tabel Transaksi Utama
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    wallet_id TEXT NOT NULL,
    category_id TEXT,
    type TEXT NOT NULL, -- 'EXPENSE', 'INCOME', 'TRANSFER'
    amount REAL NOT NULL,
    transaction_date DATETIME NOT NULL,
    merchant_name TEXT,
    receipt_image_path TEXT, -- Path file lokal: "file:///data/.../receipt_01.jpg"
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- 5. Tabel Rincian Item dari Nota Belanja (Itemized Breakdown)
CREATE TABLE transaction_items (
    id TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL,
    item_name TEXT NOT NULL,
    quantity REAL DEFAULT 1,
    unit_price REAL NOT NULL,
    total_price REAL NOT NULL,
    category_id TEXT,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- 6. Indexing untuk Performa Query Skala Besar
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_budgets_period ON budgets(year, month);
```

---

## 7. Struktur Payload JSON Parser Nota

Standar output JSON dari pipeline OCR lokal sebelum disajikan ke *Quick Verification Screen*:

```json
{
  "merchant": {
    "name": "Indomaret Point",
    "suggested_category": "Groceries"
  },
  "transaction": {
    "datetime": "2026-08-28T10:15:00Z",
    "currency": "IDR",
    "payment_method_detected": "CASH"
  },
  "items": [
    {
      "item_name": "Roti Tawar Kupas",
      "quantity": 1,
      "unit_price": 16000,
      "total_price": 16000
    },
    {
      "item_name": "Air Mineral 600ml",
      "quantity": 2,
      "unit_price": 4000,
      "total_price": 8000
    }
  ],
  "summary": {
    "subtotal": 24000,
    "discount": 0,
    "tax": 0,
    "grand_total": 24000
  },
  "local_image_temp_path": "file:///cache/temp_scan_01.jpg"
}
```

---

## 8. Rekomendasi Tech Stack (Offline-First)

| Komponen | Opsi React Native / Expo | Opsi Flutter | Fungsi & Peran |
| :--- | :--- | :--- | :--- |
| **Framework UI** | React Native (Expo) | Flutter | Framework aplikasi mobile cross-platform (Android & iOS). |
| **On-Device OCR** | `@react-native-ml-kit/text-recognition` | `google_mlkit_text_recognition` | Ekstraksi teks dari nota secara lokal tanpa server. |
| **Local Database** | **Expo SQLite + Drizzle ORM** (atau `op-sqlite`) | **Drift** (SQLite ORM) | Penyimpanan relasional transaksi, dompet, dan itemized data. |
| **File Management** | `expo-file-system` | `path_provider` | Manajemen penyimpanan file foto nota di direktori internal. |
| **Key-Value Storage** | `react-native-mmkv` | `shared_preferences` | Penyimpanan preferensi tema, status onboarding, dan flag PIN. |
| **Laporan & Export** | `xlsx` + `expo-sharing` | `excel` + `share_plus` | Generate dan bagikan file CSV/Excel langsung dari HP. |

---

## 9. Non-Functional Requirements (NFR)

* **Performance & Latency:**
  * Pemrosesan OCR *end-to-end* (Pre-processing $\rightarrow$ Parsing JSON) $\le 2.5$ detik pada perangkat kelas menengah (*mid-range*).
  * Render grafik dan riwayat transaksi harus stabil pada 60 FPS untuk $\ge 10.000$ transaksi.
  * *Cold start* aplikasi $\le 1.2$ detik.
* **Privacy & Security:**
  * 100% *Offline-First* tanpa panggilan API eksternal untuk pemrosesan OCR maupun data finansial.
  * Penyimpanan PIN aman menggunakan *hardware keystore / secure enclave*.
* **Storage Optimization:**
  * Foto nota dikompresi menggunakan format JPEG kualitas 75% dengan batas lebar maksimal 1280px (ukuran rata-rata $\le 200\text{ KB}$ per nota).
* **Data Integrity (ACID):**
  * Setiap mutasi saldo transaksi wajib dieksekusi dalam satu blok transaksi database SQLite (`BEGIN TRANSACTION ... COMMIT`) untuk mencegah ketidaksinkronan saldo saat terjadi force-close/crash.

---

## 10. Success Metrics & KPIs

| Metrik | Target Pasca Rilis | Cara Pengukuran |
| :--- | :--- | :--- |
| **OCR Field Accuracy** | $\ge 85\%$ akurasi ekstraksi | Persentase field (Total, Merchant, Tanggal) yang tidak diubah pengguna pada form verifikasi. |
| **Time-to-Log Reduction** | $\le 8$ detik total flow | Waktu yang dibutuhkan dari membuka kamera hingga transaksi tersimpan. |
| **Crash-Free Sessions** | $\ge 99.9\%$ | Metrik OS-level crash reporting / log sesi internal. |
| **Data Integrity Error** | $0$ saldo mismatch | Verifikasi audit otomatis antara log mutasi transaksi dan `current_balance`. |

---

## 11. Release Phasing & Roadmap

* **Phase 1 (MVP / Core Launch):**
  * Integrasi On-Device OCR Scanner + Pre-processing gambar.
  * Quick Verification Screen (*split-view*).
  * CRUD Transaksi & Multi-Wallet.
  * Penyimpanan foto lokal & SQLite database engine.
  * Ekspor riwayat ke CSV.
* **Phase 2 (Analytics & Budgeting):**
  * Modul Budgeting dengan Overspending Alert (80% & 100%).
  * Visual Analytics (Grafik Cash Flow & Diagram Komposisi Kategori).
  * Ekspor laporan ke format Excel (XLSX) dan PDF.
  * Itemized split expense & Kustomisasi Kategori.
  * App Security Lock (PIN & Biometrik).
* **Phase 3 (Optimization & Automation):**
  * Custom Regex Rule Builder (pengguna dapat melatih pola parser untuk struk khusus).
  * Recurring Transaction Scheduler & Local Push Notifications.
  * Database Backup/Restore dump file (`.sqlite` / `.json`).
  * Opsi enkripsi database lokal (SQLCipher).
