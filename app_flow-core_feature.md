# Blueprint Aplikasi Keuangan: Smart Receipt Scanner (Offline-First / Local Storage)

Dokumen ini berisi rancangan lengkap **App Flow**, **Core Features**, **Arsitektur Pemrosesan OCR On-Device**, **Skema Database SQLite**, serta **Tech Stack Lokal** untuk aplikasi pencatat keuangan tanpa server (*serverless/offline-first*).

---

## 1. Core Features (Fitur Utama)

### A. Smart Input & On-Device OCR Scanner
1. **On-Device Receipt Scanner (Camera & Gallery)**:
   - Pemindaian struk belanja langsung di perangkat tanpa perlu koneksi internet.
   - Ekstraksi otomatis: Nama Merchant/Toko, Tanggal & Waktu, Daftar Item (Nama, Qty, Harga Satuan), Subtotal, Pajak/Diskon, dan Grand Total.
2. **Auto-Perspective & Image Enhancement**:
   - Auto-crop sudut nota, perataan orientasi (*dewarping*), dan filter kontras otomatis untuk struk termal yang pudar.
3. **Quick Verification Screen**:
   - Tampilan *split screen* (atas: foto nota lokal, bawah: form isian otomatis) untuk verifikasi cepat 2–3 detik sebelum disimpan.
4. **Fallback Manual Input**:
   - Form input manual instan untuk transaksi tunai tanpa struk atau nota yang rusak total.

---

### B. Manajemen Transaksi & Saldo Lokal
1. **Rule-Based Auto-Categorization**:
   - Pengkategorian otomatis berbasis kata kunci lokal (*regex/keyword matching*) dari nama merchant atau item (contoh: "Indomaret / Beras" $\rightarrow$ *Groceries*, "SPBU / Pertamina" $\rightarrow$ *Transportasi*).
2. **Multi-Wallet / Multi-Account**:
   - Pencatatan saldo terpisah untuk Tunai, Rekening Bank, dan E-Wallet (GoPay, OVO, ShopeePay, dll).
3. **Split Transaction & Itemized Expense**:
   - Satu nota belanja dapat dipecah ke beberapa kategori berbeda berdasarkan rincian item barang.
4. **Recurring Transactions**:
   - Pengingat otomatis dan template transaksi rutin (langganan bulanan, sewa kos, tagihan listrik).

---

### C. Budgeting, Kontrol & Arsip Lokal
1. **Local Category Budgeting**:
   - Penentuan target batas pengeluaran per kategori setiap bulan.
2. **Instant Overspending Alert**:
   - Peringatan visual instan di dashboard saat pengeluaran kategori mencapai 80% dan 100% dari limit.
3. **Cash Flow & Visual Analytics**:
   - Grafik tren pengeluaran mingguan/bulanan, perbandingan *Income vs Expense*, dan diagram lingkaran komposisi kategori.
4. **Local Receipt Digital Archive**:
   - Foto nota dikompresi dan disimpan di direktori internal perangkat, terhubung langsung dengan ID transaksi terkait.
5. **Local Backup & Export**:
   - Ekspor data transaksi ke format Excel (XLSX), CSV, dan PDF.
   - Fitur Backup/Restore berupa file dump database lokal (`.sqlite` / `.json`) yang bisa dipindahkan secara manual.

---

## 2. On-Device Receipt Processing Pipeline (Alur Pemrosesan Lokal)

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

## 3. End-to-End App Flow (Peta Navigasi Aplikasi)

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

## 4. Skema Database Lokal (SQLite)

Berikut adalah struktur tabel relasional yang dioptimalkan untuk database lokal (SQLite):

```sql
-- Tabel Manajemen Dompet / Akun
CREATE TABLE wallets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL, -- Contoh: "Dompet Tunai", "BCA", "GoPay"
    type TEXT NOT NULL, -- 'CASH', 'BANK', 'E_WALLET', 'CREDIT'
    initial_balance REAL DEFAULT 0,
    current_balance REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Kategori Pengeluaran & Pemasukan
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL, -- Contoh: "Groceries", "Makan & Minum", "Transportasi"
    type TEXT NOT NULL, -- 'EXPENSE', 'INCOME'
    icon TEXT,
    color TEXT
);

-- Tabel Target Anggaran Bulanan
CREATE TABLE budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    monthly_limit REAL NOT NULL,
    month INTEGER NOT NULL, -- 1-12
    year INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- Tabel Transaksi Utama
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

-- Tabel Rincian Item dari Nota Belanja (Itemized Breakdown)
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
```

---

## 5. Struktur Payload JSON Parser Nota

Format standar yang dihasilkan dari pipeline OCR lokal sebelum dimasukkan ke form verifikasi:

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

## 6. Rekomendasi Tech Stack (Offline-First)

| Komponen | Opsi React Native / Expo | Opsi Flutter | Fungsi |
| :--- | :--- | :--- | :--- |
| **Framework** | React Native (Expo) | Flutter | Antarmuka aplikasi mobile cross-platform. |
| **On-Device OCR** | `@react-native-ml-kit/text-recognition` | `google_mlkit_text_recognition` | Ekstraksi teks dari nota secara lokal tanpa server. |
| **Local Database** | **Expo SQLite + Drizzle ORM** (atau `op-sqlite`) | **Drift** (SQLite ORM) | Penyimpanan relasional transaksi, dompet, dan itemized data. |
| **File Management** | `expo-file-system` | `path_provider` | Manajemen penyimpanan file foto nota di direktori internal. |
| **Key-Value Storage** | `react-native-mmkv` | `shared_preferences` | Penyimpanan preferensi tema, status onboarding, dan PIN. |
| **Laporan & Export** | `xlsx` + `expo-sharing` | `excel` + `share_plus` | Generate dan bagikan file CSV/Excel langsung dari HP. |

---

## 7. Best Practices Manajemen Data & Media Lokal

* **Penyimpanan Foto Terpisah**: Jangan simpan foto nota dalam bentuk Base64/BLOB di dalam tabel SQLite. Kompres foto ke format JPEG (kualitas 75%), simpan di direktori aplikasi (`app_data/receipts/`), dan simpan *string path*-nya di kolom `receipt_image_path`.
* **Database Indexing**: Tambahkan index pada kolom `transactions(transaction_date)` dan `transactions(wallet_id)` untuk memastikan performa query grafik dan riwayat tetap cepat meski sudah memiliki puluhan ribu data.
* **Database Transactions (ACID)**: Saat menyimpan transaksi pengeluaran, bungkus query `INSERT INTO transactions` dan `UPDATE wallets SET current_balance = current_balance - amount` dalam satu blok transaksi database (`BEGIN TRANSACTION ... COMMIT`) untuk mencegah ketidaksinkronan saldo.
