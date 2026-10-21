import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/currencies.dart';

/// Status cache kurs setelah refresh terakhir.
enum RateStatus { uninitialized, fresh, stale, none }

/// Snapshot kurs dari open.er-api.com, di-cache per hari.
///
/// API dipanggil sekali per buka app (atau saat tanggal berubah) untuk
/// menghindari pemanggilan berlebih. Gagal fetch tidak menghapus cache lama —
/// UI menampilkan umur kurs supaya user tahu data mungkin bukan hari ini.
class ExchangeRateService {
  static const String _cacheKey = 'fx_rate_cache';
  static const Duration _maxAge = Duration(hours: 24);
  static const Duration _retryBackoff = Duration(hours: 6);

  /// base → tanggal publikasi (YYYY-MM-DD) → rates → waktu fetch (ms epoch).
  String? _base;
  String? _date;
  Map<String, double>? _rates;
  int? _fetchedAt;

  RateStatus status = RateStatus.uninitialized;

  final Future<http.Response> Function(String url) _get;

  ExchangeRateService({Future<http.Response> Function(String url)? httpClient})
      : _get = httpClient ?? _defaultGet;

  static Future<http.Response> _defaultGet(String url) =>
      http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

  bool get hasCache => _rates != null;

  /// Tanggal publikasi kurs (YYYY-MM-DD) sesuai cache terakhir. [null] bila
  /// belum ada.
  String? get date => _date;

  /// Umur cache dalam ms sejak terakhir fetch berhasil. 0 bila belum ada.
  int get ageMs =>
      _fetchedAt == null ? 0 : DateTime.now().millisecondsSinceEpoch - _fetchedAt!;

  /// Baca cache dari SharedPreferences. Memuat ulang status agar UI konsisten.
  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      status = RateStatus.none;
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _base = map['base'] as String?;
      _date = map['date'] as String?;
      _fetchedAt = map['fetchedAt'] as int?;
      _rates = (map['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      status = ageMs <= _maxAge.inMilliseconds
          ? RateStatus.fresh
          : RateStatus.stale;
    } catch (_) {
      // JSON rusak → buang, anggap belum ada cache.
      await prefs.remove(_cacheKey);
      _rates = null;
      status = RateStatus.none;
    }
  }

  /// Kurs untuk 1 IDR dalam [code]. `null` bila asing dan tak ada cache.
  double? rateFor(String code) {
    if (code == kBaseCurrency) return 1.0;
    return _rates?[code];
  }

  /// Konversi nominal asing ke IDR. `null` bila kurs tak tersedia.
  double? toBase(double amount, String code) {
    final rate = rateFor(code);
    if (rate == null) return null;
    return amount / rate;
  }

  /// Refresh bila perlu (tanpa cache, tanggal berubah, atau sudah tua).
  /// Fetch gagal dipertahankan sebagai [RateStatus.stale], bukan dihapus.
  Future<void> refreshIfStale({bool force = false}) async {
    if (!force && !_needsRefresh()) return;
    final ok = await _fetchRemote();
    if (!ok) {
      status = hasCache ? RateStatus.stale : RateStatus.none;
    }
  }

  bool _needsRefresh() {
    if (!hasCache) return true;
    if (ageMs > _maxAge.inMilliseconds) return true;
    if (_date != _today()) return true;
    // Backoff: jangan tebeli API lagi terlalu cepat setelah kegagalan.
    if (status == RateStatus.stale && ageMs < _retryBackoff.inMilliseconds) {
      return false;
    }
    return false;
  }

  Future<bool> _fetchRemote() async {
    try {
      final res = await _get('https://open.er-api.com/v6/latest/$kBaseCurrency');
      if (res.statusCode != 200) return false;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['result'] != 'success') return false;
      final rates = (map['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      _base = kBaseCurrency;
      _date = _today();
      _rates = rates;
      _fetchedAt = DateTime.now().millisecondsSinceEpoch;
      status = RateStatus.fresh;
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'base': _base,
        'date': _date,
        'rates': _rates,
        'fetchedAt': _fetchedAt,
      }),
    );
  }

  static String _today() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }
}
