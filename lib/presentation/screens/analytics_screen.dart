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
  int _selectedTypeIndex = 0; // 0: Expenses, 1: Income
  int _selectedPeriodIndex = 1; // 0: Daily, 1: Weekly, 2: Monthly
  int? _selectedBarIndex;

  bool get _isExpense => _selectedTypeIndex == 0;
  String get _txType => _isExpense ? 'EXPENSE' : 'INCOME';

  List<String> _periodTabs(AppStrings s) => [s.daily, s.weekly, s.monthly];

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);
    final now = DateTime.now();

    // ── 1. Category breakdown (scoped to current month) ──
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};
    var monthTotal = 0.0;
    for (final tx in financeProvider.transactions) {
      if (tx.type != _txType) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      if (d.month != now.month || d.year != now.year) continue;
      final catName = tx.category?.name ?? s.umum;
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;
      categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
      monthTotal += tx.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ── 2. Weekly day-by-day data (Mon–Sun) ──
    final List<double> dayAmounts = List.filled(7, 0.0);
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));

    for (final tx in financeProvider.transactions) {
      if (tx.type != _txType) continue;
      final txDate = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      final diffDays = txDate
          .difference(DateTime(currentWeekMonday.year, currentWeekMonday.month,
              currentWeekMonday.day))
          .inDays;
      if (diffDays >= 0 && diffDays < 7) {
        dayAmounts[diffDays] += tx.amount;
      }
    }

    var maxDayAmount = 0.0;
    var highestDayIndex = (now.weekday - 1).clamp(0, 6);
    for (var i = 0; i < dayAmounts.length; i++) {
      if (dayAmounts[i] > maxDayAmount) {
        maxDayAmount = dayAmounts[i];
        highestDayIndex = i;
      }
    }

    // Use wallet balance as the basis for bar height proportions.
    // Each bar = (dayAmount / totalBalance), capped at 100%.
    final totalBalance = financeProvider.totalBalance;
    final hasBalance = totalBalance > 0;

    final activeIndex = _selectedBarIndex ?? highestDayIndex;
    final activeAmount = dayAmounts[activeIndex];
    final activePercent = hasBalance
        ? ((activeAmount / totalBalance) * 100).clamp(0.0, 100.0)
        : 0.0;

    // ── 3. Insight ──
    final insight = _isExpense
        ? financeProvider.topExpenseCategory
        : _topIncomeCategory(financeProvider, now);

    final heroTotal = monthTotal > 0
        ? monthTotal
        : (_isExpense
            ? financeProvider.monthlyExpense
            : financeProvider.monthlyIncome);

    // ── Active bar gradient & glow based on type ──
    final activeBarGradient =
        _isExpense ? AppColors.barActiveGradient : AppColors.barIncomeGradient;
    final activeBarGlow =
        _isExpense ? AppColors.primary : AppColors.statusPositive;
    final tooltipDotColor =
        _isExpense ? const Color(0xFF3B82F6) : const Color(0xFF4EDEA3);

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
                // ═══════════════════════════════════════════
                // EXPENSE / INCOME TOGGLE (NEW)
                // ═══════════════════════════════════════════
                _GlassTypeToggle(
                  labels: [s.expensesTab, s.incomeTab],
                  icons: const [
                    Icons.trending_down_rounded,
                    Icons.trending_up_rounded,
                  ],
                  index: _selectedTypeIndex,
                  onChanged: (i) => setState(() {
                    _selectedTypeIndex = i;
                    _selectedBarIndex = null; // reset bar selection
                  }),
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════════
                // PERIOD TABS (Daily / Weekly / Monthly)
                // ═══════════════════════════════════════════
                GlassSegmentedTabs(
                  labels: _periodTabs(s),
                  index: _selectedPeriodIndex,
                  onChanged: (i) => setState(() => _selectedPeriodIndex = i),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════
                // GLASS HERO: Total + Bar Chart
                // ═══════════════════════════════════════════
                GlassPanel(
                  padding: const EdgeInsets.all(24),
                  fill: AppColors.heroCardGradient,
                  glowBlobs: true,
                  child: Column(
                    children: [
                      Text(
                        CurrencyFormatter.formatRupiah(heroTotal),
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

                      // Day inspector pill
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
                              decoration: BoxDecoration(
                                color: activeBarGlow,
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
                              activeAmount > 0
                                  ? '${CurrencyFormatter.formatRupiah(activeAmount)} (${activePercent.toStringAsFixed(1)}%)'
                                  : (_isExpense ? s.noSpending : s.noIncome),
                              style: AppTypography.caption.copyWith(
                                color: activeAmount > 0
                                    ? (_isExpense
                                        ? AppColors.primaryLight
                                        : AppColors.statusPositive)
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bar chart
                      SizedBox(
                        height: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final isActive = i == activeIndex;
                            // Bar height = day amount as % of total balance.
                            // Floor at 0.05 so zero-amount days still show a
                            // sliver; cap at 0.90 to leave tooltip headroom.
                            final factor = hasBalance
                                ? (dayAmounts[i] / totalBalance).clamp(
                                    dayAmounts[i] > 0 ? 0.05 : 0.03, 0.90)
                                : (maxDayAmount > 0
                                    ? (dayAmounts[i] / maxDayAmount)
                                        .clamp(0.10, 0.78)
                                    : 0.10);

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
                                                    ? activeBarGradient
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
                                                          color: activeBarGlow
                                                              .withValues(alpha: 0.65),
                                                          blurRadius: 24,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (isActive && activeAmount > 0)
                                            Positioned(
                                              bottom: barHeight + 8,
                                              child: _ChartTooltip(
                                                label: CurrencyFormatter
                                                    .formatRupiah(activeAmount),
                                                percent: hasBalance
                                                    ? '${((dayAmounts[activeIndex] / totalBalance) * 100).clamp(0, 100).toStringAsFixed(1)}%'
                                                    : null,
                                                dotColor: tooltipDotColor,
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

                      // Tap hint
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

                // ═══════════════════════════════════════════
                // INSIGHT ROW
                // ═══════════════════════════════════════════
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
                          color: (_isExpense
                                  ? AppColors.primary
                                  : AppColors.statusPositive)
                              .withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            size: 20,
                            color: _isExpense
                                ? AppColors.primaryLight
                                : AppColors.statusPositive),
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
                                  ? (_isExpense
                                      ? s.insightTopCategory(
                                          insight.name, insight.percent)
                                      : s.insightTopIncomeCategory(
                                          insight.name, insight.percent))
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

                // ═══════════════════════════════════════════
                // CATEGORY BREAKDOWN
                // ═══════════════════════════════════════════
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isExpense
                          ? s.categoryBreakdown
                          : s.incomeCategoryBreakdown,
                      style: AppTypography.titleSm,
                    ),
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
                        Icon(
                          _isExpense
                              ? Icons.pie_chart_outline_rounded
                              : Icons.account_balance_wallet_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isExpense ? s.noSpendingData : s.noIncomeData,
                          style: AppTypography.bodyBold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isExpense ? s.noSpendingDataHint : s.noIncomeDataHint,
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...sortedCategories.map((entry) {
                    final percentage =
                        monthTotal > 0 ? (entry.value / monthTotal) : 0.0;
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

                // ═══════════════════════════════════════════
                // EXPORT CARD
                // ═══════════════════════════════════════════
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

  /// Top income category for insight card (mirrors topExpenseCategory logic).
  ({String name, double amount, int percent})? _topIncomeCategory(
      FinanceProvider provider, DateTime now) {
    final byCategory = <String, double>{};
    var total = 0.0;
    for (final t in provider.transactions) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transactionDate);
      if (t.type != 'INCOME' || d.month != now.month || d.year != now.year) {
        continue;
      }
      final name = t.category?.name ?? 'Umum';
      byCategory[name] = (byCategory[name] ?? 0) + t.amount;
      total += t.amount;
    }
    if (byCategory.isEmpty || total <= 0) return null;
    final top = byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (
      name: top.key,
      amount: top.value,
      percent: ((top.value / total) * 100).round(),
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
    } else if (lower.contains('gaji') || lower.contains('salary') || lower.contains('upah')) {
      return _CategoryMeta(Icons.payments_rounded, AppColors.statusPositive);
    } else if (lower.contains('bonus') || lower.contains('hadiah') || lower.contains('gift')) {
      return _CategoryMeta(Icons.card_giftcard_rounded, AppColors.meshViolet);
    } else if (lower.contains('investasi') || lower.contains('invest') || lower.contains('dividen')) {
      return _CategoryMeta(Icons.show_chart_rounded, AppColors.meshCyan);
    } else if (lower.contains('freelance') || lower.contains('proyek') || lower.contains('project')) {
      return _CategoryMeta(Icons.work_rounded, AppColors.meshIndigo);
    }
    return _CategoryMeta(Icons.category_rounded, AppColors.primaryLight);
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXPENSE / INCOME TOGGLE (Stitch v2 pill with icons)
// ═══════════════════════════════════════════════════════════════════

/// Matches the Stitch v2 HTML:
/// `p-1 bg-[#151926]/70 backdrop-blur-xl border border-white/10 rounded-full`
/// with an active pill: `bg-primary-container text-white shadow-[0_4px_16px...]`
class _GlassTypeToggle extends StatelessWidget {
  const _GlassTypeToggle({
    required this.labels,
    required this.icons,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xB3151926), // #151926 at 70%
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0DFFFFFF), // inset shimmer approximation
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primaryContainer : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: i == index
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[i],
                        size: 18,
                        color: i == index
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              i == index ? FontWeight.w600 : FontWeight.w500,
                          color: i == index
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CHART TOOLTIP
// ═══════════════════════════════════════════════════════════════════

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({
    required this.label,
    this.percent,
    this.dotColor = const Color(0xFF3B82F6),
  });

  final String label;
  final String? percent;
  final Color dotColor;

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
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: dotColor, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                percent != null ? '$label ($percent)' : label,
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
