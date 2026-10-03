import 'package:flutter_test/flutter_test.dart';
import 'package:recify/domain/ocr/gemini_models.dart';

void main() {
  group('kGeminiModels', () {
    test('5 model, id unik, default 3.6-flash ada', () {
      expect(kGeminiModels.length, 5);
      final ids = kGeminiModels.map((m) => m.id).toList();
      expect(ids.toSet().length, 5);
      expect(ids, contains(defaultGeminiModelId));
      expect(defaultGeminiModelId, 'gemini-3.6-flash');
    });

    test('blurb ID/EN non-kosong untuk semua model', () {
      for (final m in kGeminiModels) {
        expect(m.shortName, isNotEmpty, reason: m.id);
        expect(m.blurbId.trim(), isNotEmpty, reason: m.id);
        expect(m.blurbEn.trim(), isNotEmpty, reason: m.id);
      }
    });

    test('lookup helper', () {
      expect(geminiModelById('gemini-3.8-flash')?.shortName, 'Flash 3.8');
      expect(geminiModelById('tak-ada'), isNull);
      expect(geminiModelShort('gemini-3.5-flash-lite'), 'Flash-Lite 3.5');
      expect(geminiModelShort('tak-ada'), 'tak-ada');
    });
  });
}
