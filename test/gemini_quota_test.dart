import 'package:flutter_test/flutter_test.dart';
import 'package:recify/domain/ocr/gemini_receipt_parser.dart';

/// Log verbatim dari user: kuota gratis habis, model 3.6-flash,
/// retry dalam 19h34m40.957758736s.
const _userLog = '''
! Gemini parser failed: You exceeded your current quota, please check your
plan and billing details. For more information on this error, head to:
https://ai.google.dev/gemini-api/docs/rate-limits. To monitor your current
usage, head to: https://ai.dev/rate-limit.
I/flutter (19965): * Quota exceeded for metric:
generativelanguage.googleapis.com/generate_content_free_tier_requests,
limit: 20, model: gemini-3.6-flash
I/flutter (19965): Please retry in 19h34m40.957758736s.
I/flutter (19965): 🔄 Falling back to regex parser...
''';

void main() {
  group('parseGeminiQuotaError', () {
    test('log user verbatim → model + retry 19h34m', () {
      final info = parseGeminiQuotaError(_userLog);
      expect(info, isNotNull);
      expect(info!.model, 'gemini-3.6-flash');
      expect(info.retryAfter.inHours, 19);
      expect(info.retryAfter.inMinutes % 60, 34);
      // availableAt ≈ now + retry (toleransi eksekusi).
      final left = info.availableAt.difference(DateTime.now());
      expect(left.inHours, 19);
    });

    test('tanpa durasi → default 24 jam', () {
      final info = parseGeminiQuotaError(
          'Error 429 RESOURCE_EXHAUSTED model: gemini-3.5-flash-lite');
      expect(info, isNotNull);
      expect(info!.model, 'gemini-3.5-flash-lite');
      expect(info.retryAfter, const Duration(hours: 24));
    });

    test('error non-kuota → null', () {
      expect(parseGeminiQuotaError('timeout after 30s'), isNull);
      expect(parseGeminiQuotaError('Failed to parse JSON: eof'), isNull);
      expect(parseGeminiQuotaError('SocketException: no route'), isNull);
    });

    test('model absen → fallback model aktif', () {
      final info = parseGeminiQuotaError('You exceeded your current quota',
          fallbackModel: 'gemini-3.8-flash');
      expect(info, isNotNull);
      expect(info!.model, 'gemini-3.8-flash');
    });

    test('format menit-detik saja', () {
      final info = parseGeminiQuotaError(
          'Quota exceeded ... Please retry in 4m12.5s ... model: gemini-3.6-flash');
      expect(info, isNotNull);
      expect(info!.retryAfter.inMinutes, 4);
    });
  });
}
