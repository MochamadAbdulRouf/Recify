import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/finance_provider.dart';
import 'glass_panel.dart';

class ObsidianHeroCard extends StatefulWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;

  const ObsidianHeroCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  @override
  State<ObsidianHeroCard> createState() => _ObsidianHeroCardState();
}

class _ObsidianHeroCardState extends State<ObsidianHeroCard> {
  // Ticks the relative "Updated X ago" label so it stays truthful even when
  // no new data arrives (otherwise it freezes at whatever build wrote).
  Timer? _ticker;
  // ponytail: privacy mask is session-only (resets on restart); persist via
  // SharedPreferences if user later wants it remembered.
  bool _masked = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _updatedLabel(int timestampMs, AppStrings s) {
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${s.minutesAgoShort}';
    if (diff.inHours < 24) return '${diff.inHours} ${s.hoursAgoShort}';
    return _shortDate(timestampMs, s);
  }

  String _shortDate(int timestampMs, AppStrings s) {
    const idMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final months = s.isEn ? enMonths : idMonths;
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${d.day} ${months[d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // "Rp 16.468.900" → "Rp •••••••••" — digits only, no thousand separators,
  // so the real figure can't be inferred from the grouping.
  String _maskAmount(double amount) => CurrencyFormatter.formatRupiah(amount)
      .replaceAll(RegExp(r'\d'), '•')
      .replaceAll('.', '');

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final finance = context.watch<FinanceProvider>();
    final trend = finance.weeklyBalanceTrend;
    final lastTs = finance.lastDataTimestamp;
    final isFlat = trend.isFlat;
    final isPositive = trend.isPositive;
    final trendColor = isFlat
        ? AppColors.textSecondary
        : (isPositive ? AppColors.statusPositive : AppColors.statusNegative);
    final trendBg = isFlat
        ? AppColors.glassIconPlate
        : (isPositive
            ? AppColors.statusPositiveBg
            : AppColors.statusNegativeBg);

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(26),
      fill: AppColors.heroCardGradient,
      glowBlobs: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: wallet status strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.walletActive,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                lastTs != null
                    ? '${s.updated} ${_updatedLabel(lastTs, s)}'
                    : '${s.updated} ${s.noDataYet}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: label (v2: TOTAL BALANCE + eye affordance)
          Row(
            children: [
              Text(
                s.totalBalance,
                style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _masked = !_masked),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _masked
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color:
                        _masked ? AppColors.secondary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 3: the figure (privacy mask: every digit → bullet, so the
          // text keeps its exact width and nothing shifts)
          Text(
            _masked
                ? _maskAmount(widget.totalBalance)
                : CurrencyFormatter.formatRupiah(widget.totalBalance),
            style: AppTypography.displayLg.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 14),

          // Row 4: the two v2 pills — weekly trend + today's activity
          Row(
            children: [
              _Pill(
                bg: trendBg,
                fg: trendColor,
                icon: isFlat
                    ? Icons.trending_flat_rounded
                    : (isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded),
                label: '${trend.label} ${s.thisWeek}',
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Pill(
                  bg: AppColors.glassIconPlate,
                  fg: AppColors.onSurfaceVariant,
                  icon: Icons.receipt_long_rounded,
                  label: s.receiptsToday(finance.todayCount),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Row 5: income / expense split
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SplitStat(
                    icon: Icons.arrow_downward_rounded,
                    label: s.income,
                    amount: widget.monthlyIncome,
                    color: AppColors.statusPositive,
                    bg: AppColors.statusPositiveBg,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.borderSubtle,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: _SplitStat(
                    icon: Icons.arrow_upward_rounded,
                    label: s.expense,
                    amount: widget.monthlyExpense,
                    color: AppColors.statusNegative,
                    bg: AppColors.statusNegativeBg,
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

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.bg,
      required this.fg,
      required this.icon,
      required this.label});

  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitStat extends StatelessWidget {
  const _SplitStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatRupiah(amount),
                style:
                    AppTypography.bodyBold.copyWith(fontSize: 12, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
