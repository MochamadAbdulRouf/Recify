import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/notifications/notification_builder.dart';
import '../components/glass_panel.dart';
import '../providers/finance_provider.dart';

/// In-app alert feed. No push notifications: every row is derived from local
/// data at build time by [NotificationBuilder], and the read state lives in
/// SharedPreferences. Opening this screen does NOT auto-mark rows read — the
/// badge has to mean something, so the user clears them deliberately.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);
    final items = finance.notifications;

    final alerts =
        items.where((n) => n.kind != NotificationKind.spendingSpike).toList();
    final insights =
        items.where((n) => n.kind == NotificationKind.spendingSpike).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  title: s.notificationsTitle,
                  trailing: items.isEmpty
                      ? null
                      : TextButton(
                          onPressed: finance.markAllNotificationsRead,
                          child: Text(
                            s.markAllRead,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? _Empty(s: s)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (alerts.isNotEmpty) ...[
                              _SectionLabel(s.notifSectionAlert),
                              for (final n in alerts)
                                _NotificationTile(
                                  notification: n,
                                  read: finance.isNotificationRead(n.id),
                                  s: s,
                                  onTap: () =>
                                      finance.markNotificationRead(n.id),
                                ),
                            ],
                            if (insights.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _SectionLabel(s.notifSectionInfo),
                              for (final n in insights)
                                _NotificationTile(
                                  notification: n,
                                  read: finance.isNotificationRead(n.id),
                                  s: s,
                                  onTap: () =>
                                      finance.markNotificationRead(n.id),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded,
                color: AppColors.textSecondary),
          ),
          Expanded(child: Text(title, style: AppTypography.titleSm)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.read,
    required this.s,
    required this.onTap,
  });

  final AppNotification notification;
  final bool read;
  final AppStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, body) = _content();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassPanel(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyBold.copyWith(
                        color: read
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(body, style: AppTypography.caption),
                  ],
                ),
              ),
              if (!read)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// (icon, colour, title, body) for each kind. Wording lives here, not in the
  /// builder, so both stay single-responsibility.
  (IconData, Color, String, String) _content() {
    final name = notification.categoryName ?? s.umum;

    switch (notification.kind) {
      case NotificationKind.budgetOver:
        return (
          Icons.warning_amber_rounded,
          AppColors.statusNegative,
          s.notifBudgetOver(name, notification.percent),
          s.notifBudgetOverBody(
            CurrencyFormatter.format(notification.amount),
            CurrencyFormatter.format(notification.reference),
          ),
        );
      case NotificationKind.budgetNear:
        return (
          Icons.trending_up_rounded,
          AppColors.statusWarning,
          s.notifBudgetNear(name, notification.percent),
          s.notifBudgetNearBody(
            CurrencyFormatter.format(
              (notification.reference - notification.amount)
                  .clamp(0, double.infinity),
            ),
          ),
        );
      case NotificationKind.spendingSpike:
        return (
          Icons.bolt_rounded,
          AppColors.meshViolet,
          s.notifSpike(name, notification.percent),
          s.notifSpikeBody(CurrencyFormatter.format(notification.reference)),
        );
      case NotificationKind.uncategorized:
        return (
          Icons.label_off_rounded,
          AppColors.meshCyan,
          s.notifUncategorized(notification.count),
          s.notifUncategorizedBody,
        );
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.statusPositiveBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.statusPositive, size: 30),
            ),
            const SizedBox(height: 18),
            Text(s.notificationsEmpty,
                textAlign: TextAlign.center, style: AppTypography.bodyBold),
            const SizedBox(height: 6),
            Text(s.notificationsEmptyHint,
                textAlign: TextAlign.center, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
