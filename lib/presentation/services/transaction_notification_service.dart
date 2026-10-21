import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/currencies.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import 'notification_router.dart';

/// Notifikasi sistem Android saat transaksi EXPENSE/INCOME tersimpan.
///
/// Copy dibangun di sini (bukan lewat [AppStrings], yang butuh context);
/// bahasa dialirkan via [updateLocale] dari LocaleProvider di main.dart.
/// Tap notifikasi diteruskan ke [NotificationRouter.process] — baik saat
/// app hidup (onDidReceiveNotificationResponse) maupun cold start
/// (getNotificationAppLaunchDetails, payload tetap dipasok plugin karena
/// tap selalu melalui launcher activit).
class TransactionNotificationService {
  TransactionNotificationService._();

  static final TransactionNotificationService I =
      TransactionNotificationService._();

  static const String _channelId = 'recify_transactions';
  static const String _channelDescription =
      'Alert expense & income transactions.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isEn = false;

  void updateLocale(bool isEn) => _isEn = isEn;

  /// Init plugin sekali per app start: buat channel + pasang callback tap.
  Future<void> init({required bool isEn}) async {
    _isEn = isEn;
    if (_initialized) return;
    _initialized = true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (resp) {
          NotificationRouter.I.process(resp.payload);
        },
      );
      // Cold start: app dibuka karena user tap notifikasi.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        NotificationRouter.I.process(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('TransactionNotificationService.init: $e');
    }
  }

  Future<bool> _ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true; // non-Android: biarkan, tanpa dialog.
    try {
      final enabled = await android.areNotificationsEnabled();
      if (enabled ?? true) return true;
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('TransactionNotificationService.permission: $e');
      return false;
    }
  }

  /// Tampilkan notifikasi untuk transaksi tercatat. TRANSFER di-skip; izin
  /// ditolak → silent (transaksi tetap tersimpan, tanpa notifikasi).
  Future<void> notifyTransactionSaved({
    required TransactionModel tx,
    required String userId,
    required String accountName,
  }) async {
    if (tx.type != 'EXPENSE' && tx.type != 'INCOME') return;
    if (!(await _ensurePermission())) return;

    final income = tx.type == 'INCOME';
    final kind = income
        ? (_isEn ? 'Income recorded' : 'Pemasukan dicatat')
        : (_isEn ? 'Expense recorded' : 'Pengeluaran dicatat');
    final isForeign = tx.currency != kBaseCurrency;
    final amount = CurrencyFormatter.format(
      tx.amount,
      isExpense: !income,
      showSign: true,
    );
    final suffix = isForeign ? ' (${tx.currency})' : '';
    final subject = tx.merchantName ?? (_isEn ? 'transaction' : 'transaksi');
    final title = '$kind$suffix';
    final body =
        '$amount · $subject · ${_isEn ? 'account' : 'akun'} $accountName';

    try {
      await _plugin.show(
        id: tx.id.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Recify transactions',
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.event,
          ),
        ),
        payload: jsonEncode({
          'kind': 'transactionSaved',
          'userId': userId,
          'txId': tx.id,
        }),
      );
    } catch (e) {
      debugPrint('TransactionNotificationService.show: $e');
    }
  }
}
