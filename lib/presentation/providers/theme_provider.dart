import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// Mode tema aplikasi: 'system' (default) | 'light' | 'dark'.
///
/// `load()` harus DI-AWAIT di main() sebelum runApp agar tidak ada flash
/// tema yang salah; `load()` memanggil [AppColors.apply] lebih dulu.
/// Ikuti pola LocaleProvider (notify lalu persist).
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'theme_mode';

  String _mode = 'system';

  /// 'system' | 'light' | 'dark'
  String get mode => _mode;

  /// Nilai tema Flutter untuk MaterialApp.themeMode.
  ThemeMode get flutterMode {
    switch (_mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Resolusi ke nilai light/dark konkret.
  bool resolveLight(Brightness platformBrightness) {
    switch (_mode) {
      case 'light':
        return true;
      case 'dark':
        return false;
      default:
        return platformBrightness == Brightness.light;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString(_prefKey) ?? 'system';
    _apply();
    notifyListeners();
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    _apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode);
  }

  /// Panggil saat platform brightness berubah (hanya relevan saat mode
  /// 'system'): apply palet lalu notify -> MaterialApp rebuild.
  void refreshSystemBrightness() {
    _apply();
    notifyListeners();
  }

  /// Sinkronkan AppColors ke resolusi saat ini.
  /// WAJIB dipanggil sebelum notifyListeners (apply dulu, baru rebuild).
  void _apply() {
    AppColors.apply(
      resolveLight(PlatformDispatcher.instance.platformBrightness),
    );
  }
}
