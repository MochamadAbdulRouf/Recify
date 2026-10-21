import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recify/core/services/exchange_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheKey = 'fx_rate_cache';

http.Response _resp(Map<String, dynamic> rates, {int code = 200}) =>
    http.Response(jsonEncode({'result': 'success', 'rates': rates}), code);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('konversi', () {
    test('rateFor IDR = 1.0; asing tanpa cache = null', () {
      final svc = ExchangeRateService();
      expect(svc.rateFor('IDR'), 1.0);
      expect(svc.rateFor('USD'), isNull);
      expect(svc.toBase(10, 'USD'), isNull);
    });

    test('toBase(10, USD) dengan rate 0.5 = 20.0', () async {
      final svc =
          ExchangeRateService(httpClient: (_) async => _resp({'USD': 0.5}));
      await svc.loadCache();
      await svc.refreshIfStale();
      expect(svc.status, RateStatus.fresh);
      expect(svc.toBase(10, 'USD'), 20.0);
    });
  });

  group('cache', () {
    test('fetch sukses tersimpan; instance baru memuatnya', () async {
      var hits = 0;
      final svc = ExchangeRateService(httpClient: (_) async {
        hits++;
        return _resp({'USD': 0.5});
      });
      await svc.loadCache();
      await svc.refreshIfStale();
      expect(hits, 1);
      expect(svc.hasCache, isTrue);

      final reloaded = ExchangeRateService(
          httpClient: (_) async => throw StateError('tidak boleh fetch'));
      await reloaded.loadCache();
      expect(reloaded.hasCache, isTrue);
      expect(reloaded.rateFor('USD'), 0.5);
    });

    test('cache lebih tua dari 24 jam jadi stale', () async {
      final svc =
          ExchangeRateService(httpClient: (_) async => _resp({'USD': 0.5}));
      await svc.loadCache();
      await svc.refreshIfStale();

      final prefs = await SharedPreferences.getInstance();
      final map =
          jsonDecode(prefs.getString(_cacheKey)!) as Map<String, dynamic>;
      map['fetchedAt'] = (map['fetchedAt'] as int) -
          const Duration(hours: 30).inMilliseconds;
      await prefs.setString(_cacheKey, jsonEncode(map));

      final reloaded = ExchangeRateService();
      await reloaded.loadCache();
      expect(reloaded.hasCache, isTrue);
      expect(reloaded.status, RateStatus.stale);
    });

    test('fetch gagal tanpa cache jadi none (blokir save)', () async {
      final svc =
          ExchangeRateService(httpClient: (_) async => _resp({}, code: 503));
      await svc.loadCache();
      await svc.refreshIfStale();
      expect(svc.status, RateStatus.none);
      expect(svc.toBase(10, 'USD'), isNull);
    });

    test('fetch gagal dengan cache lama jadi stale, cache dipakai', () async {
      final svc =
          ExchangeRateService(httpClient: (_) async => _resp({'USD': 0.5}));
      await svc.loadCache();
      await svc.refreshIfStale();

      final failing =
          ExchangeRateService(httpClient: (_) async => _resp({}, code: 503));
      await failing.loadCache();
      await failing.refreshIfStale(force: true);
      expect(failing.status, RateStatus.stale);
      expect(failing.rateFor('USD'), 0.5);
    });

    test('JSON rusak dibuang, status none', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, 'not-json');

      final svc = ExchangeRateService();
      await svc.loadCache();
      expect(svc.hasCache, isFalse);
      expect(svc.status, RateStatus.none);
    });
  });
}
