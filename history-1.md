Plan mode read-only. Tulis file dilarang.
Salin blok bawah manual ke history:
# Plan FX auto-convert → IDR

Keputusan: dompet tetap IDR, kurs offline+manual editable per transaksi, tahap 1 USD/SGD/MYR/JPY.

1. Data+migrasi: `transaction_model.dart` tambah `originalAmount,originalCurrency='IDR',exchangeRate=1.0`; `database_helper.dart` v1→v2 + `ALTER TABLE` + backfill; `amount` tetap IDR.
2. Domain baru `lib/domain/fx/fx_table.dart`: default rate map + override via `shared_preferences`; `toIdr=round(original*rate)`.
3. Parser: `gemini_receipt_parser.dart` tambah deteksi `currency` + schema; `parsed_receipt_data.dart` normalisasi whitelist fallback IDR; `indonesian_receipt_parser.dart` fallback `$→USD,S$→SGD,RM→MYR,¥→JPY`.
4. UI: `manual_transaction_screen.dart` + `quick_verification_screen.dart` dropdown valas + field kurs prefill editable + preview `≈ Rp X`; snapshot kurs di `notes`.
5. Tampil: `currency_formatter.dart`, `transaction_detail_screen.dart`, `transaction_list_item.dart` dual `USD 10 → Rp 162rb @16.200` bila asing; total/chart tetap IDR.
6. Setting: `settings_screen.dart` menu `Kurs Valas` edit 4 rate + reset; `app_strings.dart` ID/EN.
7. Export/test: `report_exporter.dart` kolom nominal asli+currency+kurs; test konversi/parsing/migrasi; `flutter analyze`, `flutter test`.

Risiko: rate default basi. Mitigasi: kurs editable + timestamp di `notes`.
Branch: `feat/fx-auto-convert-idr` dari `main`. Skipped: API live, dompet multi-currency, 10+ valas.
