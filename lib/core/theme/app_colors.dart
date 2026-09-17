import 'package:flutter/material.dart';

class AppColors {
  // Deep Navy Canvas & Surfaces
  // Aligned to Stitch v2 "Obsidian Flux" screens — neutral ramp drifts navy.
  // Semantic income/expense colours are intentionally NOT taken from v2.
  static const Color bgCanvas = Color(0xFF0F131D);
  static const Color bgSurface = Color(0xFF171B26); // surface-container-low
  static const Color bgSurfaceElevated = Color(0xFF1C1F2A); // surface-container
  static const Color surfaceContainerLowest = Color(0xFF0A0E18);
  static const Color surfaceContainerLow = Color(0xFF171B26);
  static const Color surfaceContainer = Color(0xFF1C1F2A);
  static const Color surfaceContainerHigh = Color(0xFF262A35);
  static const Color surfaceContainerHighest = Color(0xFF313540);
  static const Color surfaceBright = Color(0xFF353944);
  static const Color surfaceDim = Color(0xFF0F131D);

  // Whisper Borders & Structural Lines (1px high-precision)
  static const Color borderSubtle = Color(0x14FFFFFF); // white 8%
  static const Color borderMedium = Color(0x26FFFFFF); // white 15%
  static const Color outline = Color(0xFF8D90A1);
  static const Color outlineVariant = Color(0xFF434655);

  // Typography & Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E95A5);
  static const Color textMuted = Color(0xFF8E95A5);
  static const Color onSurface = Color(0xFFDFE2F1);
  static const Color onSurfaceVariant = Color(0xFFC3C5D8);

  // Singular Calibrated Accent (Stitch override: Electric Blue)
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryLight = Color(0xFFB5C4FF);
  static const Color primaryContainer = Color(0xFF2F6BFF);
  static const Color onPrimaryContainer = Color(0xFF000318);

  // Functional Semantic Accents — NOT v2's cyan. Green = money in, red = out.
  static const Color secondary = Color(0xFF4EDEA3); // Mint (income)
  static const Color secondaryFixed = Color(0xFF6FFBBE);
  static const Color secondaryContainer = Color(0x264EDEA3);
  static const Color statusPositive = Color(0xFF4EDEA3);
  static const Color statusPositiveBg = Color(0x1F4EDEA3);

  static const Color error = Color(0xFFDF2F51); // Rose Coral (expense)
  static const Color errorContainer = Color(0x26DF2F51);
  static const Color statusNegative = Color(0xFFDF2F51);
  static const Color statusNegativeBg = Color(0x1FDF2F51);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0x1FF59E0B);

  // Atmospheric Mesh Accents (Stitch tokens)
  static const Color meshIndigo = Color(0xFF4F46E5);
  static const Color meshCyan = Color(0xFF06B6D4);
  static const Color meshViolet = Color(0xFF8B5CF6);

  // --- Glass kit (values verbatim from the Stitch v2 HTML) ---
  // #151926 at 60% — the stat panel fill.
  static const Color glassFill = Color(0x99151926);
  static const Color glassBorder = Color(0x1FFFFFFF); // white 12%
  static const Color glassSheen = Color(0x0AFFFFFF); // white 4%
  static const Color glassHighlight = Color(0x26FFFFFF); // white 15% inset top
  static const Color glassTooltip = Color(0xE60B0F1A); // #0b0f1a at 90%
  static const Color glassIconPlate = Color(0x14FFFFFF); // white 8%

  // Bespoke Card Gradients
  static const LinearGradient cardRimGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x332F6BFF),
      Color(0x0AFFFFFF),
      Color(0x1A4EDEA3),
    ],
  );

  /// v2 hero: from-surface-container-high/90 to-surface-container-low/80
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xE6262A35),
      Color(0xCC171B26),
    ],
  );

  /// Active bar / primary fill: from-[#3b82f6] to-[#1d4ed8]
  static const LinearGradient barActiveGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF1D4ED8),
    ],
  );

  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2F6BFF),
      Color(0xFF2A5AE8),
    ],
  );
}
