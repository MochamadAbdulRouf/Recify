import 'package:intl/intl.dart';

/// Parser tanggal nota yang toleran — satu sumber kebenaran untuk jalur
/// regex & Gemini.
///
/// Aturan:
/// - Format realistis: ISO, DD/MM (konvensi ID, didahulukan), nama bulan
///   EN, dan MM/DD AS terakhir (urutan = prioritas).
/// - **Round-trip**: hasil parse harus mem-format ulang persis seperti
///   input — menangkap parse lenient yang menormalisasi ngawur
///   (mis. `09/15/2024` dibaca DD/MM → bulan 15 → DateTime normalizes).
/// - Rentang wajar: 1990 … sekarang +30 hari — nota lama terbaca DITERIMA
///   (umur diatur Task 2 di layar verifikasi). Gagal → null (fallback).
/// Normalisasi ejaan bulan ID lama/varian + kapitalisasi sebelum parse:
/// intl locale 'id' hanya kenal "Februari"/"November"/"Agu"/"Sep" — bukan
/// "Pebruari", "Nopember", "Agt", "Sept" — dan parse nama bulan case-
/// sensitive ("nov" gagal, "Nov" lolos). Round-trip di bawah membandingkan
/// dengan string TERNORMALISASI ini. Word-boundary + case-insensitive.
String _normalizeIdAliases(String s) {
  var out = s;
  const aliases = [
    ['pebruari', 'Februari'],
    ['nopember', 'November'],
    ['sept', 'Sep'],
    ['peb', 'Feb'],
    ['nop', 'Nov'],
    ['agt', 'Agu'],
  ];
  for (final a in aliases) {
    out = out.replaceAll(RegExp(r'\b' + a[0] + r'\b', caseSensitive: false), a[1]);
  }
  // Title-case kata huruf (Nov, September, Februari) — intl butuh kapital.
  out = out.replaceAllMapped(RegExp(r'[A-Za-z]{3,}'), (m) {
    final w = m.group(0)!;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  });
  return out;
}

DateTime? parseReceiptDate(String input) {
  final raw = _normalizeIdAliases(input.trim());
  if (raw.isEmpty) return null;

  // Catatan locale: format berisi MMM/MMMM harus diuji dua locale (EN
  // default + 'id') karena intl hanya cocok dengan nama bulan locale yang
  // dipakai — "3 Mei 2024"/"15 Pebruari 2024" tuli di EN. pemanggil harus
  // initializeDateFormatting('id') sekali di main().
  //
  // Format ':ID' diuji dua kali: tanggal ganjil mencegahnya menyamarkan
  // yang AS (MM/dd tetap kalah prioritas).
  const formats = [
    // ISO (padded + unpadded)
    'yyyy-MM-dd',
    'yyyy-M-d',
    'yyyy/MM/dd',
    'yyyy/M/d',
    // DD/MM — konvensi Indonesia, sebelum MM/DD
    'dd/MM/yyyy',
    'd/M/yyyy',
    'dd-MM-yyyy',
    'd-M-yyyy',
    'dd.MM.yyyy',
    'd.M.yyyy',
    'dd/MM/yy',
    'd/M/yy',
    'dd-MM-yy',
    'd-M-yy',
    // Nama bulan EN
    'd MMM yyyy',
    'd MMMM yyyy',
    'MMM d, yyyy',
    'MMMM d, yyyy',
    // Nama bulan ID (Pebruari/Maret/Mei/Desember tak ada di EN)
    'd MMMM yyyy:ID',
    'MMMM d, yyyy:ID',
    // MM/DD AS — paling akhir (ambigu 09/10/2024 tetap DD/MM)
    'MM/dd/yyyy',
    'M/d/yyyy',
  ];

  for (final spec in formats) {
    final sep = spec.indexOf(':');
    final f = sep == -1 ? spec : spec.substring(0, sep);
    final locale = sep == -1 ? null : spec.substring(sep + 1);
    try {
      final d =
          locale == null ? DateFormat(f).parse(raw) : DateFormat(f, locale).parse(raw);
      final roundTrip = locale == null
          ? DateFormat(f).format(d)
          : DateFormat(f, locale).format(d);
      if (roundTrip == raw &&
          d.isAfter(DateTime(1990)) &&
          d.isBefore(DateTime.now().add(const Duration(days: 30)))) {
        return d;
      }
    } catch (_) {
      // coba format berikutnya
    }
  }
  return null;
}

/// Ekstrak tanggal pertama yang valid dari blok teks (OCR mentah):
/// cari kandidat via pola numerik + nama bulan, uji [parseReceiptDate].
DateTime? extractReceiptDate(String text) {
  if (text.trim().isEmpty) return null;
  final patterns = [
    r'\b(\d{1,2}/\d{1,2}/\d{4})\b',
    r'\b(\d{1,2}-\d{1,2}-\d{4})\b',
    r'\b(\d{1,2}\.\d{1,2}\.\d{4})\b',
    r'\b(\d{4}-\d{1,2}-\d{1,2})\b',
    r'\b(\d{4}/\d{1,2}/\d{1,2})\b',
    r'\b(\d{1,2}/\d{1,2}/\d{2})\b',
    r'\b(\d{1,2}-\d{1,2}-\d{2})\b',
    // Nama bulan EN: "15 Sep 2024", "15 September 2024", "Sep 15, 2024"
    r'\b(\d{1,2}\s+[A-Za-z]{3,9}\.?,?\s+\d{4})\b',
    r'\b([A-Za-z]{3,9}\.?\s+\d{1,2},?\s+\d{4})\b',
  ];
  for (final pattern in patterns) {
    // Semua kecocokan — kandidat pertama bisa jadi angka acak.
    for (final m in RegExp(pattern).allMatches(text)) {
      final parsed = parseReceiptDate(m.group(1)!);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
