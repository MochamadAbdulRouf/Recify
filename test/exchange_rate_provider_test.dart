import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recify/presentation/providers/exchange_rate_provider.dart';
import 'package:recify/core/services/exchange_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ageLabel: kurs 2 hari lalu', () async {
    final twoDaysAgo = DateTime.now().millisecondsSinceEpoch -
        const Duration(days: 2).inMilliseconds;
    SharedPreferences.setMockInitialValues({
      'fx_rate_cache': jsonEncode({
        'base': 'IDR',
        'date': '2026-10-14',
        'rates': {'USD': 0.5},
        'fetchedAt': twoDaysAgo,
      }),
    });

    final svc = ExchangeRateService(
        httpClient: (_) async => http.Response('down', 503));
    final provider = ExchangeRateProvider(service: svc);
    await provider.init();

    expect(provider.status, RateStatus.stale);
    expect(provider.ageLabel, contains('14 Okt'));
    expect(provider.ageLabel, contains('2 hari lalu'));
  });

  test('ageLabel kosong tanpa cache', () async {
    final svc = ExchangeRateService(
        httpClient: (_) async => http.Response('down', 503));
    final provider = ExchangeRateProvider(service: svc);
    await provider.init();

    expect(provider.ageLabel, '');
    expect(provider.toBase(10, 'USD'), isNull);
  });
}
