import 'package:flutter/material.dart';

class AppColors {
  // Deep Matte Obsidian Canvas & Surfaces (Zero Pure Black)
  // Aligned to Stitch DESIGN.md "Obsidian Flux" — neutral graphite, no blue/violet cast
  static const Color bgCanvas = Color(0xFF090A0F);
  static const Color bgSurface = Color(0xFF121318);
  static const Color bgSurfaceElevated = Color(0xFF1B1E2B);
  static const Color surfaceContainer = Color(0xFF1E1F25);
  static const Color surfaceContainerHigh = Color(0xFF292A2F);
  static const Color surfaceContainerHighest = Color(0xFF34343A);
  static const Color surfaceDim = Color(0xFF121318);

  // Whisper Borders & Structural Lines (1px high-precision)
  static const Color borderSubtle = Color(0x18FFFFFF);
  static const Color borderMedium = Color(0x28FFFFFF);
  static const Color outline = Color(0xFF6B7280);
  static const Color outlineVariant = Color(0xFF374151);

  // Typography & Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color onSurface = Color(0xFFE5E7EB);
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);

  // Singular Calibrated Accent (Stitch override: Electric Blue)
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryLight = Color(0xFFB5C4FF);
  static const Color primaryContainer = Color(0xFF2F6BFF);
  static const Color onPrimaryContainer = Color(0xFF000318);

  // Functional Semantic Accents (Stitch: mint positive / red-coral negative)
  static const Color secondary = Color(0xFF4EDEA3); // Mint
  static const Color secondaryFixed = Color(0xFF6FFBBE);
  static const Color secondaryContainer = Color(0x264EDEA3);
  static const Color statusPositive = Color(0xFF4EDEA3);
  static const Color statusPositiveBg = Color(0x1F4EDEA3);

  static const Color error = Color(0xFFDF2F51); // Rose Coral (Stitch tertiary-container)
  static const Color errorContainer = Color(0x26DF2F51);
  static const Color statusNegative = Color(0xFFDF2F51);
  static const Color statusNegativeBg = Color(0x1FDF2F51);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0x1FF59E0B);

  // Atmospheric Mesh Accents (Stitch tokens)
  static const Color meshIndigo = Color(0xFF4F46E5);
  static const Color meshCyan = Color(0xFF06B6D4);
  static const Color meshViolet = Color(0xFF8B5CF6);

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

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B1E2B),
      Color(0xFF121318),
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
