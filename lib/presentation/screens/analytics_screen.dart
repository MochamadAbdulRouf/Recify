import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
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
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        title: Text('Statistik & Analisis', style: AppTypography.headlineMd),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Row(
                    children: [
                      _buildSummaryBadge(
                        label: 'Total Pemasukan',
                        amount: CurrencyFormatter.formatRupiah(totalIncome),
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryBadge(
                        label: 'Transaksi',
                        amount: '${financeProvider.transactions.length} Total',
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Category Breakdown Section
            Text('Distribusi Kategori Pengeluaran', style: AppTypography.titleSm),
            const SizedBox(height: 12),

            if (sortedCategories.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Belum ada data pengeluaran untuk dianalisis',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ...sortedCategories.map((entry) {
                final catName = entry.key;
                final amount = entry.value;
                final count = categoryCounts[catName] ?? 1;
                final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;

                // Distinct colors for top categories
                Color barColor = AppColors.primaryLight;
                if (catName.toLowerCase().contains('makan') || catName.toLowerCase().contains('food')) {
                  barColor = AppColors.meshViolet;
                } else if (catName.toLowerCase().contains('belanja') || catName.toLowerCase().contains('shop')) {
                  barColor = AppColors.meshCyan;
                } else if (catName.toLowerCase().contains('tagihan')) {
                  barColor = AppColors.secondary;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(catName, style: AppTypography.bodyBold),
                              const SizedBox(height: 2),
                              Text('$count Transaksi', style: AppTypography.caption),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.formatRupiah(amount), style: AppTypography.bodyBold),
                              const SizedBox(height: 2),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}%',
                                style: AppTypography.caption.copyWith(
                                  color: barColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage.clamp(0.02, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 100), // Navbar padding
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              amount,
              style: AppTypography.bodyBold.copyWith(
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
