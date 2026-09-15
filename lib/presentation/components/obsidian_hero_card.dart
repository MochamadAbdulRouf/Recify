import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/finance_provider.dart';

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
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${s.minutesAgoShort}';
    if (diff.inHours < 24) return '${diff.inHours} ${s.hoursAgoShort}';
    return _shortDate(timestampMs, s);
  }

  String _shortDate(int timestampMs, AppStrings s) {
    const idMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final months = s.isEn ? enMonths : idMonths;
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${d.day} ${months[d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final finance = context.watch<FinanceProvider>();
    final trend = finance.weeklyBalanceTrend;
    final lastTs = finance.lastDataTimestamp;
    final isFlat = trend.isFlat;
    final isPositive = trend.isPositive;
    final trendLabel = trend.label;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top-right atmospheric glow (restrained)
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Wallet status strip (Stitch style)
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

                const SizedBox(height: 14),

                // Row 2: Label + weekly expense trend pill (Stitch +14.4% badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.totalBalance,
                      style: AppTypography.caption.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFlat
                              ? AppColors.surfaceContainerHigh
                              : (isPositive ? AppColors.statusPositiveBg : AppColors.statusNegativeBg),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFlat ? Icons.trending_flat_rounded : (isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                              size: 14,
                              color: isFlat
                                  ? AppColors.textSecondary
                                  : (isPositive ? AppColors.secondary : AppColors.error),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trendLabel,
                              style: AppTypography.caption.copyWith(
                                color: isFlat
                                    ? AppColors.textSecondary
                                    : (isPositive ? AppColors.secondary : AppColors.error),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Large Numerical Balance
                Text(
                  CurrencyFormatter.formatRupiah(widget.totalBalance),
                  style: AppTypography.displayLg.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 18),

                // Income / Expense split
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Monthly Income
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.statusPositiveBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.income,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.formatRupiah(widget.monthlyIncome),
                                    style: AppTypography.bodyBold.copyWith(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Subtle Divider
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.borderSubtle,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // Monthly Expense
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.statusNegativeBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.expense,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.formatRupiah(widget.monthlyExpense),
                                    style: AppTypography.bodyBold.copyWith(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
