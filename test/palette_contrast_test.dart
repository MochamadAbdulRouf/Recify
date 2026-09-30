import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/theme/app_colors.dart';

/// WCAG AA contrast gate untuk KEDUA palet (dark & light).
/// Jalankan: flutter test test/palette_contrast_test.dart
///
/// `AppColors.apply(...)` memilih palet — token yang sama dibaca ulang
/// untuk tiap tema, jadi assertion menutup kedua arah.
void main() {
  double luminance(Color c) {
    final argb = c.toARGB32();
    double channel(int shift) {
      final s = ((argb >> shift) & 0xFF) / 255.0;
      return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
  }

  double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  List<(Color, Color, double, String)> pairs() => [
        (AppColors.textPrimary, AppColors.bgCanvas, 4.5, 'textPrimary/bgCanvas'),
        (AppColors.textPrimary, AppColors.bgSurfaceElevated, 4.5,
            'textPrimary/bgSurfaceElevated (toast message)'),
        (AppColors.textSecondary, AppColors.bgSurface, 4.5,
            'textSecondary/bgSurface'),
        (AppColors.onSurface, AppColors.bgSurface, 4.5, 'onSurface/bgSurface'),
        (AppColors.onSurfaceVariant, AppColors.bgSurface, 4.5,
            'onSurfaceVariant/bgSurface'),
        (AppColors.textMuted, AppColors.bgCanvas, 4.5, 'textMuted/bgCanvas'),
        (AppColors.primaryLight, AppColors.bgCanvas, 4.5,
            'primaryLight/bgCanvas (link/ikon kecil)'),
        (const Color(0xFFFFFFFF), AppColors.primaryContainer, 4.5,
            'teks putih (default activeTextColor) di pill biru'),
        (const Color(0xFF003824), const Color(0xFF4EDEA3), 4.5,
            'teks hijau tua di pill mint (tab expense/income)'),
        (AppColors.statusPositive, AppColors.bgSurfaceElevated, 4.5,
            'toast title sukses'),
        (AppColors.errorText, AppColors.bgSurfaceElevated, 4.5,
            'toast title gagal'),
        (const Color(0xFFFFFFFF), const Color(0xFF2563EB), 4.5,
            'putih di CTA gradient stop pertama'),
        (AppColors.outline, AppColors.bgCanvas, 3.0, 'outline/kontrol'),
        (AppColors.statusPositive, AppColors.bgCanvas, 3.0, 'status ikon'),
        (AppColors.error, AppColors.bgCanvas, 3.0, 'error ikon'),
      ];

  for (final isLight in [false, true]) {
    final themeName = isLight ? 'LIGHT' : 'DARK';
    test('WCAG AA — palet $themeName', () {
      AppColors.apply(isLight);
      for (final (fg, bg, min, label) in pairs()) {
        final r = ratio(fg, bg);
        expect(
          r >= min,
          isTrue,
          reason:
              '$themeName: $label = ${r.toStringAsFixed(2)}:1 (min $min) '
              'fg=0x${fg.toARGB32().toRadixString(16)} '
              'bg=0x${bg.toARGB32().toRadixString(16)}',
        );
      }
    });
  }
}
