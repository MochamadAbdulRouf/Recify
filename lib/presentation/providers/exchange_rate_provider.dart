import 'package:flutter/foundation.dart';

import '../../core/services/exchange_rate_service.dart';

/// Status kurs valas untuk seluruh aplikasi.
///
/// Menyalakan [ExchangeRateService] sekali, memicu refresh saat app resume,
/// dan mengekspos umur kurs ke UI. Semua layar baca [rateFor]/[toBase] lewat
/// provider ini supaya satu sumber kebenaran.
class ExchangeRateProvider extends ChangeNotifier {
  ExchangeRateProvider({ExchangeRateService? service})
      : _service = service ?? ExchangeRateService();

  final ExchangeRateService _service;
  bool _loading = false;

  bool get loading => _loading;
  RateStatus get status => _service.status;
  bool get hasCache => _service.hasCache;
  String? get date => _service.date;
  int get ageMs => _service.ageMs;

  /// Kurs 1 IDR dalam [code]; [null] bila asing dan tanpa cache.
  double? rateFor(String code) => _service.rateFor(code);

  /// Konversi asing → IDR; [null] bila kurs tak tersedia.
  double? toBase(double amount, String code) => _service.toBase(amount, code);

  /// Muat cache + refresh bila perlu (dipanggil sekali saat app mulai).
  Future<void> init() async {
    await _service.loadCache();
    notifyListeners();
    await refreshIfStale();
  }

  /// Refresh saat app resume; tidak memblokir UI.
  Future<void> refreshIfStale({bool force = false}) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    await _service.refreshIfStale(force: force);
    _loading = false;
    notifyListeners();
  }

  /// Sapaan umur kurs untuk caption di bawah pemilih mata uang.
  /// Contoh: "kurs per 16 Okt" atau "kurs per 14 Okt, 2 hari lalu".
  String get ageLabel {
    final d = _service.date;
    if (d == null) return '';
    final parts = d.split('-');
    if (parts.length != 3) return 'kurs per $d';
    final months = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final mIdx = int.tryParse(parts[1]) ?? 1;
    final month = months[(mIdx - 1).clamp(0, 11)];
    final label = 'kurs per ${int.parse(parts[2])} $month';
    final days = _service.ageMs ~/ Duration.millisecondsPerDay;
    return days >= 1 ? '$label, $days hari lalu' : label;
  }
}
