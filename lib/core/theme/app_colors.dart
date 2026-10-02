import 'package:flutter/material.dart';

/// Token warna semantic "Obsidian Flux".
///
/// Nilai mengikuti tema aktif — dipanggil `AppColors.apply(isLight)` dari
/// ThemeProvider SEBELUM runApp (anti-flash) dan setiap kali mode berubah.
/// Nama publik stabil; jangan pernah hardcode hex di layar — pakai token ini.
///
/// Palet light disusun sendiri (bukan inverse mekanis dark):
/// kontras teks utama ≥4.5:1 di kedua tema (lihat test/palette_contrast_test.dart).
class AppColors {
  AppColors._();

  static bool _light = false;

  /// Terapkan palet. `isLight` = hasil resolusi ThemeProvider
  /// (mode sistem || pilihan eksplisit).
  static void apply(bool isLight) => _light = isLight;
  static bool get isLight => _light;

  // ── Deep Navy Canvas & Surfaces (dark) / Soft Gray (light) ──
  static Color get bgCanvas =>
      _light ? const Color(0xFFF5F6F8) : const Color(0xFF0B0F19);
  static Color get bgSurface =>
      _light ? const Color(0xFFFFFFFF) : const Color(0xFF171B26);
  static Color get bgSurfaceElevated =>
      _light ? const Color(0xFFFFFFFF) : const Color(0xFF1C1F2A);
  static Color get surfaceContainerLowest =>
      _light ? const Color(0xFFFAFBFC) : const Color(0xFF060A12);
  static Color get surfaceContainerLow =>
      _light ? const Color(0xFFF7F8FA) : const Color(0xFF171B26);
  static Color get surfaceContainer =>
      _light ? const Color(0xFFFFFFFF) : const Color(0xFF1C1F2A);
  static Color get surfaceContainerHigh =>
      _light ? const Color(0xFFEDEEF2) : const Color(0xFF262A35);
  static Color get surfaceContainerHighest =>
      _light ? const Color(0xFFE3E5EA) : const Color(0xFF313540);
  static Color get surfaceBright =>
      _light ? const Color(0xFFF0F1F4) : const Color(0xFF353944);
  // Di light dipakai sebagai pulau nav → putih (elevated), bukan "dim".
  static Color get surfaceDim =>
      _light ? const Color(0xFFFFFFFF) : const Color(0xFF0B0F19);

  // ── Whisper Borders & Structural Lines (1px) ──
  static Color get borderSubtle =>
      _light ? const Color(0x0F000000) : const Color(0x14FFFFFF);
  static Color get borderMedium =>
      _light ? const Color(0x24000000) : const Color(0x26FFFFFF);
  static Color get outline =>
      _light ? const Color(0xFF6B7280) : const Color(0xFF8D90A1);
  static Color get outlineVariant =>
      _light ? const Color(0xFFC6C9D1) : const Color(0xFF434655);

  // ── Typography & Text ──
  static Color get textPrimary =>
      _light ? const Color(0xFF121318) : const Color(0xFFFFFFFF);
  static Color get textSecondary =>
      _light ? const Color(0xFF565B66) : const Color(0xFF8E95A5);
  static Color get textMuted =>
      _light ? const Color(0xFF5F6573) : const Color(0xFF8E95A5);
  static Color get onSurface =>
      _light ? const Color(0xFF1C1F2A) : const Color(0xFFDFE2F1);
  static Color get onSurfaceVariant =>
      _light ? const Color(0xFF525766) : const Color(0xFFC3C5D8);

  // ── Singular Calibrated Accent (Electric Blue) ──
  static Color get primary => const Color(0xFF2F6BFF); // sama di dua tema
  // Light: biru tua — pale blue #B5C4FF gagal AA di atas putih.
  static Color get primaryLight =>
      _light ? const Color(0xFF1D4ED8) : const Color(0xFFB5C4FF);
  // #2F6BFF + putih = 4.47:1 (mepet AA); #2563EB → 5.1:1.
  static Color get primaryContainer => const Color(0xFF2563EB);
  static Color get onPrimaryContainer =>
      _light ? const Color(0xFFFFFFFF) : const Color(0xFF000318);

  // ── Functional Semantic Accents. Green = money in, red = out. ──
  static Color get secondary =>
      _light ? const Color(0xFF047857) : const Color(0xFF4EDEA3);
  static Color get secondaryFixed => const Color(0xFF6FFBBE); // glow, fixed
  static Color get secondaryContainer =>
      _light ? const Color(0x1A047857) : const Color(0x264EDEA3);
  static Color get statusPositive =>
      _light ? const Color(0xFF047857) : const Color(0xFF4EDEA3);
  static Color get statusPositiveBg =>
      _light ? const Color(0x1A047857) : const Color(0x1F4EDEA3);

  static Color get error =>
      _light ? const Color(0xFFD91E3F) : const Color(0xFFDF2F51);

  /// Varian [error] khusus TEKS kecil di atas surface gelap.
  /// `error` gelap (L≈0.17) hanya 3.65:1 di atas #1C1F2A — cukup untuk
  /// fill/ikon tapi gagal AA untuk judul toast; varian ini L≈0.37 (≥5:1).
  /// Untuk teks di surface terang cukup pakai [error] biasa.
  static Color get errorText =>
      _light ? const Color(0xFFD91E3F) : const Color(0xFFFF7A8C);
  static Color get errorContainer =>
      _light ? const Color(0x1AD91E3F) : const Color(0x26DF2F51);
  static Color get statusNegative =>
      _light ? const Color(0xFFD91E3F) : const Color(0xFFDF2F51);
  static Color get statusNegativeBg =>
      _light ? const Color(0x1AD91E3F) : const Color(0x1FDF2F51);
  static Color get statusWarning =>
      _light ? const Color(0xFFB45309) : const Color(0xFFF59E0B);
  static Color get statusWarningBg =>
      _light ? const Color(0x1AB45309) : const Color(0x1FF59E0B);

  // ── Atmospheric Mesh Accents ──
  static Color get meshIndigo => const Color(0xFF4F46E5);
  static Color get meshCyan => const Color(0xFF06B6D4);
  static Color get meshViolet => const Color(0xFF8B5CF6);

  // ── Glass kit ──
  static Color get glassFill =>
      _light ? const Color(0xBFFFFFFF) : const Color(0x99151926);
  static Color get glassBorder =>
      _light ? const Color(0x14000000) : const Color(0x1FFFFFFF);
  static Color get glassSheen =>
      _light ? const Color(0x0AFFFFFF) : const Color(0x0AFFFFFF);
  static Color get glassHighlight =>
      _light ? const Color(0x0F000000) : const Color(0x26FFFFFF);
  // Pill tooltip gelap di dua tema: elevated, teks putih kontras aman.
  static Color get glassTooltip => const Color(0xE60B0F1A);
  static Color get glassIconPlate =>
      _light ? const Color(0x0F000000) : const Color(0x14FFFFFF);

  // ── Fills generik (track, bar inactive) — ganti Colors.white@0.08 ──
  /// Di atas surface: 8% putih (dark) / 6% hitam (light).
  static Color get subtleFill =>
      _light ? const Color(0x0F000000) : const Color(0x14FFFFFF);

  /// Varian lebih samar (bar inactive periode berjalan).
  static Color get subtleFillDim =>
      _light ? const Color(0x08000000) : const Color(0x0AFFFFFF);

  /// Track toggle off.
  static Color get toggleTrack =>
      _light ? const Color(0x1F000000) : const Color(0xB3151926);

  // ── Bespoke Card Gradients ──
  static LinearGradient get cardRimGradient => _light
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2A2F6BFF), Color(0x0A000000), Color(0x1A047857)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x332F6BFF), Color(0x0AFFFFFF), Color(0x1A4EDEA3)],
        );

  /// v2 hero — dark: navy tints; light: wash biru-abu tipis di putih.
  static LinearGradient get heroCardGradient => _light
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF3FC), Color(0xFFE3E9F7)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6262A35), Color(0xCC171B26)],
        );

  /// Active bar / primary fill: from-[#3b82f6] to-[#1d4ed8] (sama dua tema).
  static LinearGradient get barActiveGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      );

  /// Income bar — light lebih pekat agar kontras vs putih ≥3:1.
  static LinearGradient get barIncomeGradient => _light
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4EDEA3), Color(0xFF10B981)],
        );

  /// Expense bar — #DF2F51 vs putih ≈4:1, aman dua tema.
  static LinearGradient get barExpenseGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDF2F51), Color(0xFF9F1239)],
      );

  /// CTA biru; putih di atas ≥5:1 — teks kecil pun lolos AA.
  static LinearGradient get primaryCtaGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF2A5AE8)],
      );
}
