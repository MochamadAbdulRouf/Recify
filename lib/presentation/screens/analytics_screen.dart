import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../components/glass_panel.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriodIndex = 1; // 0: Daily, 1: Weekly, 2: Monthly
  int? _selectedBarIndex;

  List<String> _periodTabs(AppStrings s) => [s.daily, s.weekly, s.monthly];

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);
    final now = DateTime.now();

    // 1. Category breakdown — scoped to the current month so it shares a basis
    //    with the hero figure. Percentages use the sum of the categories shown
    //    as denominator, which keeps them at or below 100%.
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};
    var monthExpense = 0.0;
    for (final tx in financeProvider.transactions) {
      if (tx.type != 'EXPENSE') continue;
      final d = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      if (d.month != now.month || d.year != now.year) continue;
      final catName = tx.category?.name ?? s.umum;
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;
      categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
      monthExpense += tx.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Weekly day-by-day spending (Mon–Sun)
    final List<double> daySpendings = List.filled(7, 0.0);
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));

    for (final tx in financeProvider.transactions) {
      if (tx.type != 'EXPENSE') continue;
      final txDate = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      final diffDays = txDate
          .difference(DateTime(currentWeekMonday.year, currentWeekMonday.month,
              currentWeekMonday.day))
          .inDays;
      if (diffDays >= 0 && diffDays < 7) {
        daySpendings[diffDays] += tx.amount;
      }
    }

    var maxDaySpend = 0.0;
    var highestSpendDayIndex = (now.weekday - 1).clamp(0, 6);
    for (var i = 0; i < daySpendings.length; i++) {
      if (daySpendings[i] > maxDaySpend) {
        maxDaySpend = daySpendings[i];
        highestSpendDayIndex = i;
      }
    }
    if (maxDaySpend <= 0) maxDaySpend = 100000.0;

    final activeIndex = _selectedBarIndex ?? highestSpendDayIndex;
    final activeSpendAmount = daySpendings[activeIndex];
    final insight = financeProvider.topExpenseCategory;
    final heroExpense = monthExpense > 0 ? monthExpense : financeProvider.monthlyExpense;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: StickyFrostedAppBar(
        height: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.statsTitle, style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              s.statsSubtitle,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassSegmentedTabs(
                  labels: _periodTabs(s),
                  index: _selectedPeriodIndex,
                  onChanged: (i) => setState(() => _selectedPeriodIndex = i),
                ),

                const SizedBox(height: 20),

                // Glass hero: figure + period line + bar chart
                GlassPanel(
                  padding: const EdgeInsets.all(24),
                  fill: AppColors.heroCardGradient,
                  glowBlobs: true,
                  child: Column(
                    children: [
                      Text(
                        CurrencyFormatter.formatRupiah(heroExpense),
                        style: AppTypography.displayLg.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _periodLine(now, s),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Day inspector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${s.daysFull[activeIndex]}: ',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              activeSpendAmount > 0
                                  ? CurrencyFormatter.formatRupiah(activeSpendAmount)
                                  : s.noSpending,
                              style: AppTypography.caption.copyWith(
                                color: activeSpendAmount > 0
                                    ? AppColors.primaryLight
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bar chart — bars sit directly on the glass, not in a nested panel
                      SizedBox(
                        height: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final isActive = i == activeIndex;
                            // 0.78 ceiling leaves headroom for the floating tooltip.
                            final factor =
                                (daySpendings[i] / maxDaySpend).clamp(0.10, 0.78);

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() => _selectedBarIndex = i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: LayoutBuilder(
                                    builder: (ctx, c) {
                                      final barHeight = c.maxHeight * factor;
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          AnimatedPositioned(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            height: barHeight,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: isActive
                                                    ? AppColors.barActiveGradient
                                                    : null,
                                                color: isActive
                                                    ? null
                                                    : Colors.white
                                                        .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: isActive
                                                      ? Colors.white
                                                          .withValues(alpha: 0.40)
                                                      : Colors.white
                                                          .withValues(alpha: 0.08),
                                                ),
                                                boxShadow: isActive
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.primary
                                                              .withValues(alpha: 0.65),
                                                          blurRadius: 24,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (isActive && activeSpendAmount > 0)
                                            Positioned(
                                              bottom: barHeight + 8,
                                              child: _ChartTooltip(
                                                label: CurrencyFormatter
                                                    .formatRupiah(activeSpendAmount),
                                              ),
                                            ),
                                          Positioned(
                                            bottom: -18,
                                            left: 0,
                                            right: 0,
                                            child: Text(
                                              s.daysShort[i],
                                              textAlign: TextAlign.center,
                                              style: AppTypography.caption.copyWith(
                                                color: isActive
                                                    ? AppColors.textPrimary
                                                    : AppColors.onSurfaceVariant,
                                                fontWeight: isActive
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 34),

                      // Tap hint, matching v2's footer rule
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                        child: Text(
                          s.tapBarHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Insight row — flat, no blur (v2 keeps this one un-glassed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            size: 20, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.insightTitle,
                              style: AppTypography.bodyBold.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight != null
                                  ? s.insightTopCategory(insight.name, insight.percent)
                                  : s.insightEmpty,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category breakdown header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.categoryBreakdown, style: AppTypography.titleSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.activeCount(sortedCategories.length),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (sortedCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.pie_chart_outline_rounded,
                            size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(s.noSpendingData, style: AppTypography.bodyBold),
                        const SizedBox(height: 4),
                        Text(
                          s.noSpendingDataHint,
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...sortedCategories.map((entry) {
                    final percentage =
                        monthExpense > 0 ? (entry.value / monthExpense) : 0.0;
                    final count = categoryCounts[entry.key] ?? 0;
                    final meta = _getCategoryMeta(entry.key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(meta.icon, size: 22, color: meta.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.totalLabel}: ${CurrencyFormatter.formatRupiah(entry.value)}',
                                    style: AppTypography.caption
                                        .copyWith(color: AppColors.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count ${s.transactionsLabel}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pie_chart_rounded, size: 13, color: meta.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: AppTypography.caption.copyWith(
                                      color: meta.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 14),

                // Export card
                GlassPanel(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_outlined,
                            size: 20, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.exportTaxReport,
                                style: AppTypography.bodyBold.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              s.exportTaxReportHint,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),

                const SizedBox(height: 132), // Space for Floating Island + FAB
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _periodLine(DateTime now, AppStrings s) {
    const idMonths = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final month = (s.isEn ? enMonths : idMonths)[now.month - 1];
    return '$month • ${s.daysFull[now.weekday - 1]}, ${now.day} • ${now.year}';
  }

  _CategoryMeta _getCategoryMeta(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('belanja') || lower.contains('shop') || lower.contains('pasar')) {
      return _CategoryMeta(Icons.shopping_bag_rounded, AppColors.meshCyan);
    } else if (lower.contains('makan') || lower.contains('food') || lower.contains('kuliner')) {
      return _CategoryMeta(Icons.restaurant_rounded, AppColors.secondary);
    } else if (lower.contains('kesehatan') || lower.contains('obat') || lower.contains('medis')) {
      return _CategoryMeta(Icons.medical_services_rounded, AppColors.error);
    } else if (lower.contains('transport') || lower.contains('bensin') || lower.contains('kendaraan')) {
      return _CategoryMeta(Icons.directions_car_rounded, AppColors.meshViolet);
    } else if (lower.contains('tagihan') || lower.contains('listrik') || lower.contains('air')) {
      return _CategoryMeta(Icons.bolt_rounded, AppColors.meshIndigo);
    } else if (lower.contains('hiburan') || lower.contains('game') || lower.contains('nonton')) {
      return _CategoryMeta(Icons.movie_rounded, AppColors.primaryLight);
    }
    return _CategoryMeta(Icons.category_rounded, AppColors.primaryLight);
  }
}

/// Floating chart tooltip: `bg-[#0b0f1a]/90 backdrop-blur-xl border-white/20`
/// with a rotated caret square underneath.
class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.glassTooltip,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderMedium),
            boxShadow: const [
              BoxShadow(color: Color(0xA6000000), blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF3B82F6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -1),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.glassTooltip,
                border: Border.all(color: AppColors.borderMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryMeta {
  final IconData icon;
  final Color color;

  _CategoryMeta(this.icon, this.color);
}
