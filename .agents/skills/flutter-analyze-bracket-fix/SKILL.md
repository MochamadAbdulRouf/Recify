---
name: flutter-analyze-bracket-fix
description: >
  Fix `flutter analyze` expected_token bracket errors after widget-wrap
  refactors in Flutter. Use when analyze reports "Expected to find ')'"
  or "Expected to find ']'" and the file was recently re-nested.
---

# Flutter Analyze Bracket-Mismatch Fix

`expected_token` setelah refactor bungkus-widget hampir selalu berarti
kurung buka/tutup tidak seimbang — bukan logika salah. Jangan tebak,
hitung dari diff.

## When to Use

- `flutter analyze` lapor `Expected to find ')'` / `Expected to find ']'`
- File baru saja di-refactor: tambah `AnimatedSwitcher`, `KeyedSubtree`,
  `Column`, tukar urutan `PressableScale` > `Padding`, dsb.
- Error line = tempat parser menyerah, BUKAN lokasi kurung yang hilang
  (kurung hilang selalu DI ATAS error line).

## Procedure

### 1. Petakan error

```bash
flutter analyze 2>&1
git status --short
git diff -- <file-bermasalah>
```

Catat: file, baris error, wrapper apa yang baru ditambah di diff.

### 2. Ambil referensi versi sehat

```bash
git show HEAD:<file> | sed -n '<awal>,<akhir>p'
```

Baris penutup versi HEAD = pola tutup yang benar. Bandingkan dengan
versi kerja: opener baru apa saja yang belum punya penutup.

### 3. Hitung dari struktur luar ke dalam

Urutkan setiap opener dari widget terluar (mis. `AnimatedSwitcher` >
`KeyedSubtree` > `Column` = 3 penutup wajib di ujung blok) lalu ke
blok yang di-refactor (`PressableScale` > `Padding` > `GestureDetector`
> `Container`). Tiap level butuh tepat satu penutup.

### 3b. Audit programmatic bila hitungan manual gagal

Bila 2-3x patch manual cuma geser error tanpa nol, berhenti tebak.
Jalankan audit depth via `execute_code` (jangan `python -c` di terminal —
classifier Windows sering tolak flag `-c`/`-e`):

- Scan file per karakter: abaikan isi string (`'...'` termasuk interpolasi
  `${...}`), komentar `//` dan `/* */`.
- Catat depth tiap baris + stack opener yang belum tertutup.
- Pada tiap mismatch, cetak stack-top: opener yatim apa, baris berapa.

Dua pertanyaan yang dijawab audit:
1. Baris penutup X tutup di depth berapa vs opener-nya di depth berapa
   → kurang berapa penutup, tambah tepat segitu.
2. Stack-top saat mismatch = opener yatim (`{` baris N tak bertuan) →
   itu penutup PALSU sisa ekstraksi, HAPUS bukan tambah.

### 4. Patch penutup saja

- Tambah/kembalikan penutup yang hilang, tanpa ubah logika/API/indent
  di luar blok itu.
- `patch` gagal "no match" = whitespace beda. Baca byte persisnya dulu,
  mis. via `read_file` + cek repr baris, lalu patch ulang.

### 5. Verifikasi dengan analyze sungguhan

```bash
flutter analyze 2>&1
```

Target: `No issues found!`. Diagnostik LSP inline saat patch bisa basi —
yang dipercaya hanya hasil `flutter analyze` ulang.

## Pitfalls

1. **Tambah penutup di tempat salah** — error pindah ke baris bawah
   (`...:688`, `...:690`). Artinya hitungan level salah: ulangi langkah 3
   dari versi HEAD, jangan tambah kurung lagi membabi buta.
2. **Refactor tukar-urutan hapus penutup ganda** — pola lama
   `Padding > PressableScale > GestureDetector` ditutup `)),` + `);`;
   sesudah jadi `PressableScale > Padding > ...` tetap butuh jumlah
   penutup yang sama. Diff yang menghapus satu baris `)),` tanpa ganti
   = tersangka utama.
2b. **Penutup PALSU sisa ekstraksi method** — blok yang diekstrak ke method
   sendiri (`_buildTabContent`) tapi penutup gaya lama (`),` + `],` + `),`
   + `);` untuk `Column > KeyedSubtree > AnimatedSwitcher > ...`) masih
   tertinggal di ujung. Gejala: audit tunjuk stack-top = SATU opener yatim
   yang sama (`{` baris N) di semua mismatch ujung file, FINAL_DEPTH 0.
   Fix = HAPUS baris palsu, bukan tambah kurung.
3. **Perbaiki satu error, muncul error baru di bawah** — normal bila
   wrapper luar (`AnimatedSwitcher` + `KeyedSubtree` + `Column`) nambah
   opener tanpa penutup di ujung blok. Tambahkan penutup setelah anak
   terakhir, sebelum `],` parent.
4. **Jangan sentuh file larangan** — di Recify `glass_panel.dart` adalah
   kode user, jangan diubah tanpa izin meski analyze menyentuh area itu.

## Verification Checklist

- [ ] `flutter analyze` → `No issues found!`
- [ ] `git diff` hanya sentuh blok bermasalah (3-10 baris tutup)
- [ ] Nol perubahan logika, API, dependensi, file baru
- [ ] `flutter run` di device: layar yang di-refactor tampil normal

## Real Case (Recify, analytics_screen.dart)

Refactor tambah `AnimatedSwitcher` + `KeyedSubtree` + `Column` (3 opener
tanpa penutup) + tukar `Padding > PressableScale` jadi
`PressableScale > Padding` (hapus 1 baris `)),`). Fix pertama salah
tempat (error geser 633 → 688/690), hitung ulang dari `git show HEAD`,
tambah 3 penutup di ujung + kembalikan `)),` pola lama → analyze bersih.

## Real Case 2 (Recify, analytics_screen.dart — 27 error)

~15 iterasi manual tambah/hapus kurung di dua titik cuma geser error
(692 → 743 → 745) tanpa nol. Audit programmatic via `execute_code`
beri jawaban pasti: titik 1 kurang 2 penutup (depth 8 vs opener depth 7
→ tambah `),` + `),`), titik 2 = 4 penutup PALSU sisa ekstraksi
`_buildTabContent` (stack-top satu `{` yatim di semua mismatch,
FINAL_DEPTH 0 → hapus 4 baris, sisakan `],` + `);`). 27 error → nol
dalam 2 patch.
