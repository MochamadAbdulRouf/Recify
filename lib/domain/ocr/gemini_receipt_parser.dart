import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/parsed_receipt_data.dart';

/// Gemini LLM-based receipt parser that takes raw OCR text and returns
/// structured receipt data via Google's Gemini API with JSON mode.
/// Info kuota habis yang diparse dari pesan error Gemini.
/// Pure + unit-testable — tidak menyentuh network/prefs.
class GeminiQuotaInfo {
  const GeminiQuotaInfo({required this.model, required this.retryAfter});

  /// ID model dari pesan error (fallback: model aktif saat itu).
  final String model;

  /// Berapa lama lagi kuota reset.
  final Duration retryAfter;

  /// Kapan model bisa dipakai lagi (dihitung saat disimpan).
  DateTime get availableAt => DateTime.now().add(retryAfter);
}

/// Parse pesan error Gemini → info kuota, atau null bila bukan error kuota.
///
/// Mengenali (case-insensitive): 'exceeded your current quota',
/// 'quota exceeded', '429', 'RESOURCE_EXHAUSTED'. Durasi dari pola
/// 'Please retry in 19h34m40.95s' (h/m opsional); absen → 24 jam.
GeminiQuotaInfo? parseGeminiQuotaError(Object e, {String? fallbackModel}) {
  final msg = e.toString();
  final lower = msg.toLowerCase();
  final isQuota = lower.contains('exceeded your current quota') ||
      lower.contains('quota exceeded') ||
      lower.contains('resource_exhausted') ||
      RegExp(r'\b429\b').hasMatch(msg);
  if (!isQuota) return null;

  var model = fallbackModel ?? 'gemini-3.6-flash';
  final modelMatch =
      RegExp(r'model:\s*([a-z0-9.\-_]+)', caseSensitive: false)
          .firstMatch(msg);
  if (modelMatch != null) model = modelMatch.group(1)!;

  var retryAfter = const Duration(hours: 24);
  final durMatch = RegExp(
    r'please retry in\s+(?:(\d+)h)?(?:(\d+)m)?([\d.]+)s',
    caseSensitive: false,
  ).firstMatch(msg);
  if (durMatch != null) {
    final h = int.tryParse(durMatch.group(1) ?? '0') ?? 0;
    final m = int.tryParse(durMatch.group(2) ?? '0') ?? 0;
    final s = double.tryParse(durMatch.group(3) ?? '0') ?? 0;
    retryAfter = Duration(
      hours: h,
      minutes: m,
      milliseconds: (s * 1000).round(),
    );
  }
  return GeminiQuotaInfo(model: model, retryAfter: retryAfter);
}

/// Jenis kegagalan Gemini untuk notifikasi & fallback antar key.
enum GeminiErrorKind { quota, overload, config, other }

/// Klasifikasi error Gemini → jenis penanganan (kuota / gangguan /
/// konfigurasi key / lainnya). Dipakai scanner untuk notifikasi & fallback
/// antar API key. Pola diturunkan dari source `google_generative_ai` 0.4.7:
/// ≥500 → `GenerativeAIException: Server Error [50x]`; 429 → teks kuota
/// verbatim; key invalid → `API_KEY_INVALID` / `API key not valid`.
GeminiErrorKind classifyGeminiError(Object e) {
  final msg = e.toString();
  final lower = msg.toLowerCase();
  // 5xx (500/503/504/529) selalu gangguan server — dicek dulu supaya
  // body seperti "RESOURCE_EXHAUSTED" tidak salah klasifikasi ke quota.
  if (RegExp(r'Server Error \[5[0-5]\d\]', caseSensitive: false)
      .hasMatch(msg)) {
    return GeminiErrorKind.overload;
  }
  if (lower.contains('exceeded your current quota') ||
      lower.contains('quota exceeded') ||
      lower.contains('resource_exhausted') ||
      RegExp(r'\b429\b').hasMatch(msg)) {
    return GeminiErrorKind.quota;
  }
  if (lower.contains('overloaded') || lower.contains('try again later')) {
    return GeminiErrorKind.overload;
  }
  if (lower.contains('api_key_invalid') ||
      lower.contains('api key not valid') ||
      lower.contains('api key expired') ||
      lower.contains('permission_denied')) {
    return GeminiErrorKind.config;
  }
  return GeminiErrorKind.other;
}

class GeminiReceiptParser {
  GenerativeModel? _model;
  String? _currentApiKey;
  String _currentModel = 'gemini-3.6-flash';

  static const String _systemPrompt = '''
Kamu adalah Receipt Parsing Engine khusus struk transaksi di Indonesia.
Tugasmu: mengekstrak teks mentah hasil OCR menjadi JSON valid dan terstruktur.

=== STRUKTUR STRUK (pisahkan 3 bagian ini) ===
A. HEADER — nama toko, alamat, kota, telp, no struk/kasir/NPWP, tanggal, jam.
   → hanya mengisi "merchant", "date"/"date_raw", "payment_method".
B. ITEMS — HANYA baris produk/jasa yang dibeli: nama, qty, harga.
C. FOOTER — subtotal, pajak (PPN/PB1/Service), diskon, grand_total.

=== ATURAN ITEMS (PALING PENTING) ===
- "items" HANYA berisi produk/jasa yang dibeli + qty + price
  (price = total per baris setelah dikali qty).
- DILARANG masuk ke "items": nama toko, alamat, kota, nomor telepon,
  nomor struk/kasir/NPWP, baris TOTAL, pajak, diskon, sisa uang,
  "kasir", "terima kasih", nama promo/voucher, sapaan.
- Jika sebuah baris meragukan dan bukan produk → JANGAN masukkan.

=== ATURAN ANGKA ===
- Bersihkan format angka: "Rp 15.000" → 15000, "22,400" → 22400.
- subtotal, tax (PPN/PB1/Service Charge), discount, grand_total
  diambil dari FOOTER, bukan dihitung ulang dari items.
- grand_total = angka final yang dibayar pelanggan (setelah pajak & diskon).

=== ATURAN VALIDASI (wajib) ===
- Cek: sum(price) ≈ subtotal (toleransi Rp 1).
- Cek: subtotal + tax - discount ≈ grand_total (toleransi Rp 1).
- Jika salah satu tidak cocok atau tidak yakin → set
  "needs_review": true dan isi "review_reason" (alasan singkat, mis.
  "sum items 57000 ≠ subtotal 60000").
- Jika semua cocok → "needs_review": false, "review_reason": null.

=== FIELD LAINNYA ===
- "date": YYYY-MM-DD saja; jika TIDAK PASTI tulis null (jangan menebak).
- "date_raw": salinan VERBATIM teks tanggal seperti tertulis di nota
  (mis. '15 Pebruari 2024', '24/11/2024'); null bila tidak ada.
  JANGAN menerjemahkan/mengubah ejaan nama bulan.
- "payment_method": "CASH" | "E_WALLET" (GOPAY/OVO/DANA/SHOPEEPAY/QRIS) |
  "BANK" (DEBIT/BCA/MANDIRI/BRI) | "CREDIT". Default "CASH".
- "category" dari nama merchant: cat_groceries (minimarket), cat_food
  (restoran/cafe), cat_transport (SPBU), cat_health (apotek),
  cat_shopping (toko retail). Default "cat_groceries".
- Output: HANYA raw JSON, tanpa Markdown triple backtick.

=== CONTOH BENAR ===
Input:
TOKO MAJU JAYA
Jl. Merdeka No. 12, Bandung
Telp 0812-3456-7890
Struk #A00123
24/11/2024 10:32
2x Kopi Susu      18000
1x Roti Bakar     12000
Subtotal          30000
PB1 10%           3000
TOTAL             33000
Bayar Tunai       50000
Terima kasih

Output:
{
  "merchant": "TOKO MAJU JAYA",
  "date": "2024-11-24",
  "date_raw": "24/11/2024",
  "category": "cat_groceries",
  "payment_method": "CASH",
  "items": [
    {"name": "Kopi Susu", "qty": 2, "price": 18000},
    {"name": "Roti Bakar", "qty": 1, "price": 12000}
  ],
  "subtotal": 30000,
  "tax": 3000,
  "discount": 0,
  "grand_total": 33000,
  "needs_review": false,
  "review_reason": null
}

=== CONTOH SALAH (dilarang) ===
"items" berisi: "TOKO MAJU JAYA", "Jl. Merdeka No. 12", "Telp 0812-3456-7890",
"TOTAL 33000", "Bayar Tunai 50000", "Terima kasih" → SEMUA INI SALAH,
baris-baris itu milik HEADER/FOOTER, bukan item pembelian.

Skema JSON output:
{
  "merchant": string,
  "date": string | null,
  "date_raw": string | null,
  "category": string,
  "payment_method": string,
  "items": [{"name": string, "qty": number, "price": number}],
  "subtotal": number,
  "tax": number,
  "discount": number,
  "grand_total": number,
  "needs_review": boolean,
  "review_reason": string | null
}
''';

  /// Initialize or re-initialize the Gemini model with the given API key.
  /// Model ikut menjadi bagian identitas — ganti bila key ATAU model berubah.
  void initialize(String apiKey, {String model = 'gemini-3.6-flash'}) {
    if (apiKey == _currentApiKey && model == _currentModel && _model != null) {
      return;
    }

    _currentApiKey = apiKey;
    _currentModel = model;
    _model = GenerativeModel(
      model: model,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, // Low temperature for consistent, deterministic output
      ),
      systemInstruction: Content.system(_systemPrompt),
    );
  }

  /// Whether the parser has been initialized with an API key.
  bool get isInitialized => _model != null;

  /// ID model yang aktif di parser ini.
  String get model => _currentModel;

  /// Parse raw OCR text into structured receipt data using Gemini API.
  ///
  /// Throws [Exception] if:
  /// - The parser hasn't been initialized with an API key
  /// - The Gemini API call fails
  /// - The response JSON is invalid or empty
  Future<ParsedReceiptData> parseOcrText(String ocrRawText, {String? imagePath}) async {
    if (_model == null) {
      throw Exception('GeminiReceiptParser belum diinisialisasi. Panggil initialize(apiKey) terlebih dahulu.');
    }

    final response = await _model!.generateContent([
      Content.text('Berikut teks mentah hasil scan OCR struk:\n\n$ocrRawText'),
    ]);

    final jsonString = response.text;
    if (jsonString == null || jsonString.isEmpty) {
      throw Exception('Gemini API mengembalikan response kosong.');
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return ParsedReceiptData.fromGeminiJson(
        decoded,
        rawText: ocrRawText,
        imagePath: imagePath,
      );
    } catch (e) {
      throw Exception('Gagal mem-parse response JSON dari Gemini: $e\nRaw response: $jsonString');
    }
  }

  /// Dispose resources (no-op for now, but keeps API consistent with MLKitReceiptScanner).
  void dispose() {
    _model = null;
    _currentApiKey = null;
  }
}
