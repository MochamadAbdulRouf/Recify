import 'package:flutter/material.dart';

class AppColors {
  // Deep Matte Obsidian Canvas & Surfaces (Zero Pure Black)
  static const Color bgCanvas = Color(0xFF090A0F);
  static const Color bgSurface = Color(0xFF12141D);
  static const Color bgSurfaceElevated = Color(0xFF1A1D2B);
  static const Color surfaceContainer = Color(0xFF1E2130);
  static const Color surfaceContainerHigh = Color(0xFF262A3C);
  static const Color surfaceContainerHighest = Color(0xFF31364C);
  static const Color surfaceDim = Color(0xFF0D0E15);

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

  // Singular Calibrated Accent (Sapphire Electric Blue)
  static const Color primary = Color(0xFF3B72FF);
  static const Color primaryLight = Color(0xFF93B4FF);
  static const Color primaryContainer = Color(0xFF2557D6);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Functional Semantic Accents (Emerald & Rose Coral)
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryFixed = Color(0xFF34D399);
  static const Color secondaryContainer = Color(0x2610B981);
  static const Color statusPositive = Color(0xFF10B981);
  static const Color statusPositiveBg = Color(0x1F10B981);

  static const Color error = Color(0xFFF43F5E); // Rose Coral
  static const Color errorContainer = Color(0x26F43F5E);
  static const Color statusNegative = Color(0xFFF43F5E);
  static const Color statusNegativeBg = Color(0x1FF43F5E);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0x1FF59E0B);

  // Subtle Atmospheric Mesh Accents (Restrained, Not Neon)
  static const Color meshIndigo = Color(0xFF4338CA);
  static const Color meshCyan = Color(0xFF0891B2);
  static const Color meshViolet = Color(0xFF6D28D9);

  // Bespoke Card Gradients
  static const LinearGradient cardRimGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x333B72FF),
      Color(0x0AFFFFFF),
      Color(0x1A10B981),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF161928),
      Color(0xFF11131E),
    ],
  );

  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B72FF),
      Color(0xFF2557D6),
    ],
  );
}
