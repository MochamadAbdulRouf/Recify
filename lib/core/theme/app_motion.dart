import 'package:flutter/material.dart';

/// Satu bahasa motion untuk semua transisi tab (bottom nav + tab chart).
/// Dipakai di semua level supaya konsisten.
const kTabTransitionDuration = Duration(milliseconds: 220);
const kTabTransitionCurve = Curves.easeOutCubic;

/// Cross-fade konten di bawah tab Expenses/Income & Daily/Weekly/Monthly.
const kTabContentFadeDuration = Duration(milliseconds: 200);
