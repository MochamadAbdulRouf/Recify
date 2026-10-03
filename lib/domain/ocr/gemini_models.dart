/// Daftar model Gemini yang bisa dipilih user untuk OCR scan.
/// Default: [defaultGeminiModelId] (perilaku lama tidak berubah).
class GeminiModelOption {
  const GeminiModelOption({
    required this.id,
    required this.shortName,
    required this.blurbId,
    required this.blurbEn,
  });

  /// ID persis untuk API (mis. 'gemini-3.6-flash').
  final String id;

  /// Nama ringkas untuk toast/badge (mis. 'Flash 3.6').
  final String shortName;

  /// Satu kalimat kesimpulan kemampuan (ID).
  final String blurbId;

  /// Satu kalimat kesimpulan kemampuan (EN).
  final String blurbEn;
}

/// Model default — sama seperti sebelum ada pilihan model.
const String defaultGeminiModelId = 'gemini-3.6-flash';

const List<GeminiModelOption> kGeminiModels = [
  GeminiModelOption(
    id: 'gemini-3.8-flash',
    shortName: 'Flash 3.8',
    blurbId:
        'Paling cerdas di keluarga Flash — untuk nota rumit dan buram, tapi paling boros token.',
    blurbEn:
        'Smartest of the Flash family — for complex, blurry receipts, but the costliest on tokens.',
  ),
  GeminiModelOption(
    id: 'gemini-3.6-flash',
    shortName: 'Flash 3.6',
    blurbId:
        'Seimbang dan andal — cocok sebagai pilihan utama dan fallback saat Lite gagal.',
    blurbEn:
        'Balanced and reliable — good default and fallback when Lite fails.',
  ),
  GeminiModelOption(
    id: 'gemini-3.5-flash',
    shortName: 'Flash 3.5',
    blurbId:
        'Cukup untuk nota sederhana; kalah menarik dibanding Flash-Lite untuk volume tinggi.',
    blurbEn:
        'Enough for simple receipts; less appealing than Flash-Lite for high volume.',
  ),
  GeminiModelOption(
    id: 'gemini-3.5-flash-lite',
    shortName: 'Flash-Lite 3.5',
    blurbId:
        'Paling hemat untuk volume tinggi dengan akurasi baik — bisa naikkan thinking bila perlu.',
    blurbEn:
        'Most efficient for high volume with good accuracy — thinking can be raised when needed.',
  ),
  GeminiModelOption(
    id: 'gemini-3.1-flash-lite',
    shortName: 'Flash-Lite 3.1',
    blurbId:
        'Paling cepat dan hemat, tapi reasoning terbatas — fallback terakhir.',
    blurbEn:
        'Fastest and cheapest, but limited reasoning — last-resort fallback.',
  ),
];

/// Cari opsi berdasarkan ID; null bila tidak dikenal.
GeminiModelOption? geminiModelById(String id) {
  for (final m in kGeminiModels) {
    if (m.id == id) return m;
  }
  return null;
}

/// Nama ringkas untuk ID model — fallback ke ID bila tak dikenal.
String geminiModelShort(String id) =>
    geminiModelById(id)?.shortName ?? id;
