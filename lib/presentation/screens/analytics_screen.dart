import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriodIndex = 1; // 0: Harian, 1: Mingguan, 2: Bulanan
  int? _selectedBarIndex;

  final List<String> _periodTabs = ['Harian', 'Mingguan', 'Bulanan'];
  final List<String> _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _dayFullNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final totalExpense = financeProvider.monthlyExpense;

    // 1. Calculate Real Category Breakdown from SQLite transactions
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};
    for (final tx in financeProvider.transactions) {
      if (tx.type == 'EXPENSE') {
        final catName = tx.category?.name ?? 'Umum';
        categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;
        categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Calculate Weekly Day-by-Day Spending (Mon-Sun)
    final List<double> daySpendings = List.filled(7, 0.0);
    final now = DateTime.now();
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));

    for (final tx in financeProvider.transactions) {
      if (tx.type == 'EXPENSE') {
        final txDate = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
        final diffDays = txDate.difference(DateTime(currentWeekMonday.year, currentWeekMonday.month, currentWeekMonday.day)).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          daySpendings[diffDays] += tx.amount;
        }
      }
    }

    // Determine max spending day for bar chart scaling
    double maxDaySpend = 0.0;
    int highestSpendDayIndex = (now.weekday - 1).clamp(0, 6);
    for (int i = 0; i < daySpendings.length; i++) {
      if (daySpendings[i] > maxDaySpend) {
        maxDaySpend = daySpendings[i];
        highestSpendDayIndex = i;
      }
    }
    if (maxDaySpend <= 0) {
      maxDaySpend = 100000.0; // Baseline scale
    }

    final activeIndex = _selectedBarIndex ?? highestSpendDayIndex;
    final activeSpendAmount = daySpendings[activeIndex];
    final activeDayName = _dayFullNames[activeIndex];

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      // Stitch Sticky Frosted Header
      appBar: StickyFrostedAppBar(
        height: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Statistik & Analisis',
              style: AppTypography.headlineMd.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              'Laporan Pengeluaran & Arus Kas',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Time Period Segment Toggle (Stitch design)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: List.generate(_periodTabs.length, (index) {
                  final isSelected = _selectedPeriodIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriodIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.bgSurfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: AppColors.borderSubtle) : null,
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _periodTabs[index],
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMd.copyWith(
                            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Stitch Total Spending & Fluid Bar Chart Card (Zero Overflow)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
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
                    // Top-right subtle sapphire ambient glow (from Stitch design)
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Spending Header & Trend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Pengeluaran',
                                    style: AppTypography.bodyReg.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.formatRupiah(totalExpense),
                                    style: AppTypography.displayLg.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              // Trend pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.trending_up_rounded, color: AppColors.error, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '12%',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Active Selected Day Inspector Pill (Stitch style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
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
                                  '$activeDayName: ',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  activeSpendAmount > 0
                                      ? CurrencyFormatter.formatRupiah(activeSpendAmount)
                                      : 'Tidak ada pengeluaran',
                                  style: AppTypography.caption.copyWith(
                                    color: activeSpendAmount > 0 ? AppColors.primaryLight : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Fluid Modern Bar Chart Canvas (Zero Overflow Guarantee)
                          SizedBox(
                            height: 130,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (i) {
                                final spend = daySpendings[i];
                                final heightFactor = (spend / maxDaySpend).clamp(0.10, 1.0);
                                final isHighlighted = i == activeIndex;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _selectedBarIndex = i;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Bar Track & Indicator
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: AnimatedFractionallySizedBox(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeOutCubic,
                                                heightFactor: heightFactor,
                                                widthFactor: 1.0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: isHighlighted
                                                        ? const LinearGradient(
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              Color(0xFF5B8EFF),
                                                              AppColors.primary,
                                                            ],
                                                          )
                                                        : null,
                                                    color: isHighlighted ? null : const Color(0xFF202436),
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(6),
                                                    ),
                                                    boxShadow: isHighlighted
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors.primary.withValues(alpha: 0.4),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Day Label
                                          Text(
                                            _dayLabels[i],
                                            style: AppTypography.caption.copyWith(
                                              color: isHighlighted ? AppColors.primaryLight : AppColors.textSecondary,
                                              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 3. Category Breakdown Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rincian Kategori Pengeluaran', style: AppTypography.titleSm),
                Text(
                  '${sortedCategories.length} Kategori',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Category Breakdown List matching Stitch Cards
            if (sortedCategories.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.pie_chart_outline_rounded, size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('Belum ada data pengeluaran', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    Text(
                      'Catat transaksi atau pindai struk untuk melihat statistik visual.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...sortedCategories.map((entry) {
                final percentage = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                final count = categoryCounts[entry.key] ?? 0;
                final meta = _getCategoryMeta(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Category Icon Squircle
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: meta.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(meta.icon, size: 20, color: meta.color),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key, style: AppTypography.bodyBold.copyWith(fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count Transaksi',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatRupiah(entry.value),
                                  style: AppTypography.bodyBold.copyWith(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: AppTypography.caption.copyWith(
                                    color: meta.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Vibrant Mesh Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 100), // Space for Floating Island Navbar
          ],
        ),
      ),
    );
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

class _CategoryMeta {
  final IconData icon;
  final Color color;

  _CategoryMeta(this.icon, this.color);
}
