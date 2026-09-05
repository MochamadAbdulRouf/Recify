import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/parsed_receipt_data.dart';

/// Gemini LLM-based receipt parser that takes raw OCR text and returns
/// structured receipt data via Google's Gemini API with JSON mode.
class GeminiReceiptParser {
  GenerativeModel? _model;
  String? _currentApiKey;

  static const String _systemPrompt = '''
Kamu adalah Receipt Parsing Engine khusus struk transaksi di Indonesia.
Tugasmu: Mengekstrak teks mentah hasil OCR menjadi format JSON yang valid dan terstruktur.

Aturan Pemrosesan:
1. Abaikan bagian Header (nama jalan, nomor RT/RW, kota, kode pos, nomor telepon kasir, nomor NPWP, nomor mesin kasir). Nomor-nomor ini BUKAN harga atau kuantitas barang.
2. Item transaksi hanya mencakup produk atau jasa yang dibeli, kuantitas (qty), dan harga akhir (price = total harga per item setelah dikali qty).
3. Bersihkan format angka dari mata uang atau pemisah ribuan (misal: "Rp 15.000" menjadi 15000, "22,400" menjadi 22400).
4. Pisahkan secara ketat nilai subtotal, tax (PPN/PB1/Service Charge), discount, dan grand_total.
5. Jika ada diskon per barang, catat harga setelah diskon pada item. Jika ada diskon global, catat pada field discount.
6. Format tanggal harus YYYY-MM-DD. Jika tanggal tidak ditemukan, gunakan null.
7. grand_total adalah angka final yang harus dibayar pelanggan (setelah pajak dan diskon).
8. Untuk field payment_method, deteksi dari teks: "CASH", "E_WALLET" (GOPAY/OVO/DANA/SHOPEEPAY/QRIS), "BANK" (DEBIT/BCA/MANDIRI/BRI), "CREDIT" (VISA/MASTERCARD). Default "CASH".
9. Untuk field category, tentukan berdasarkan nama merchant: "cat_groceries" (minimarket/supermarket), "cat_food" (restoran/cafe), "cat_transport" (SPBU/bensin), "cat_health" (apotek), "cat_shopping" (toko retail). Default "cat_groceries".
10. Hanya keluarkan raw JSON tanpa format Markdown triple backtick.

Skema JSON output:
{
  "merchant": string,
  "date": string | null,
  "category": string,
  "payment_method": string,
  "items": [{"name": string, "qty": number, "price": number}],
  "subtotal": number,
  "tax": number,
  "discount": number,
  "grand_total": number
}
''';

  /// Initialize or re-initialize the Gemini model with the given API key.
  void initialize(String apiKey) {
    if (apiKey == _currentApiKey && _model != null) return;

    _currentApiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-3.6-flash',
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
