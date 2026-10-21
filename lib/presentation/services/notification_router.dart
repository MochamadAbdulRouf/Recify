import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/app_strings.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/user_model.dart';
import '../components/app_toast.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../screens/transaction_detail_screen.dart';

/// Router untuk tap notifikasi transaksi.
///
/// Payload berisi akun + txId: bila akun aktif sama, langsung buka detail;
/// bila akun berbeda, pindah ke akun pemilik (bila masih terbuka) dulu.
/// Cold start: payload tiba lewat `getNotificationAppLaunchDetails`; bila
/// context belum siap, disimpan ke prefs lalu diproses oleh
/// [processPendingFromStorage] post-frame.
class NotificationRouter {
  NotificationRouter._();

  static final NotificationRouter I = NotificationRouter._();

  static const String _pendingKey = 'notif_tap_pending';

  String? _lastProcessed;
  ({String userId, String txId})? _deferred;

  Future<void> process(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    Map<String, dynamic> p;
    try {
      p = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final userId = p['userId'] as String?;
    final txId = p['txId'] as String?;
    if (userId == null || txId == null) return;

    final key = '$userId|$txId';
    if (key == _lastProcessed) return;
    _lastProcessed = key;

    await _dispatch(userId, txId);
  }

  /// Coba lagi tap yang tersimpan saat context belum siap.
  Future<void> processPendingFromStorage() async {
    if (_deferred != null) {
      final d = _deferred!;
      _deferred = null;
      await _dispatch(d.userId, d.txId);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null) return;
      await prefs.remove(_pendingKey);
      await process(raw);
    } catch (_) {}
  }

  Future<void> _dispatch(String userId, String txId) async {
    var ctx = AppToast.navigatorKey.currentContext;
    if (ctx == null) {
      _deferred = (userId: userId, txId: txId);
      // Persist supaya tidak hilang bila user mematikan app sekarang.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _pendingKey,
          jsonEncode({'userId': userId, 'txId': txId}),
        );
      } catch (_) {}
      return;
    }

    final auth = ctx.read<AuthProvider>();
    final s = AppStrings.of(ctx);
    if (auth.currentUser?.id != userId) {
      final users = await auth.fetchAllUsers();
      UserModel? target;
      for (final u in users) {
        if (u.id == userId) target = u;
      }
      if (target == null) {
        AppToast.error(s.notifTapOtherAccount);
        return;
      }
      if (!target.hasLoggedIn) {
        AppToast.error(s.notifTapAccountLocked);
        return;
      }
      await auth.switchTo(target);
      if (!ctx.mounted) return;
      AppToast.success(AppStrings.of(ctx).accountSwitched(target.name));
    }

    // FinanceProvider diisi AuthGate post-frame setelah switchTo; beri
    // waktu loadInitialData hingga transaksi target masuk cache.
    TransactionModel? tx;
    for (var attempt = 0; attempt < 6; attempt++) {
      final readCtx = AppToast.navigatorKey.currentContext;
      if (readCtx != null && readCtx.mounted) {
        final finance = readCtx.read<FinanceProvider>();
        for (final t in finance.transactions) {
          if (t.id == txId) tx = t;
        }
      }
      if (tx != null) break;
      await Future.delayed(const Duration(milliseconds: 400));
    }
    final pushCtx = AppToast.navigatorKey.currentContext;
    if (tx == null || pushCtx == null || !pushCtx.mounted) return;
    Navigator.of(pushCtx).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx!),
      ),
    );
  }
}
