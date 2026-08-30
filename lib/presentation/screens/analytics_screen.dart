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
  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final totalExpense = financeProvider.monthlyExpense;
    final totalIncome = financeProvider.monthlyIncome;

    // Calculate real category breakdown
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

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: StickyFrostedAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Statistik & Analisis', style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              'Rincian Pengeluaran & Arus Kas',
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
            // 1. Total Spending Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pengeluaran Bulan Ini',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatRupiah(totalExpense),
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniSummary(
                        label: 'Total Pemasukan',
                        amount: totalIncome,
                        color: AppColors.secondary,
                      ),
                      _buildMiniSummary(
                        label: 'Sisa Arus Kas',
                        amount: totalIncome - totalExpense,
                        color: (totalIncome - totalExpense) >= 0 ? AppColors.secondary : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Category Breakdown Section
            Text('Rincian Kategori Pengeluaran', style: AppTypography.titleSm),
            const SizedBox(height: 12),

            if (sortedCategories.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.pie_chart_outline_rounded, size: 36, color: AppColors.textSecondary),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada data pengeluaran',
                      style: AppTypography.bodyBold,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data grafik kategori akan otomatis terbentuk setelah Anda mencatat transaksi.',
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.category_rounded,
                                    size: 16,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key, style: AppTypography.bodyBold),
                                    Text(
                                      '$count transaksi',
                                      style: AppTypography.caption.copyWith(fontSize: 10),
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
                                  style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildMiniSummary({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatRupiah(amount),
          style: AppTypography.bodyBold.copyWith(color: color, fontSize: 14),
        ),
      ],
    );
  }
}
