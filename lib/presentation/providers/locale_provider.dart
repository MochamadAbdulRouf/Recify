import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_notification_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'locale_code';

  String _code = 'id';

  String get localeCode => _code;
  bool get isEn => _code == 'en';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_prefKey) ?? 'id';
    notifyListeners();
    // Notifikasi sistem: init sekali per app start + ikut bahasa aktif.
    unawaited(TransactionNotificationService.I.init(isEn: isEn));
  }

  Future<void> setLocale(String code) async {
    _code = code;
    notifyListeners();
    TransactionNotificationService.I.updateLocale(isEn);
    await SharedPreferences.getInstance().then((p) => p.setString(_prefKey, code));
  }
}
