import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../screens/transaction_detail_screen.dart';
import 'pressable.dart';

/// Bottom sheet rincian transaksi satu kategori (drill-down Stats).
/// Daftar difilter pemanggil (tipe + kategori + periode aktif).
/// Klik item → halaman detail penuh. Tanpa gradient/animasi.
class CategoryTransactionsSheet extends StatelessWidget {
  const CategoryTransactionsSheet({
    super.key,
    required this.categoryName,
    required this.transactions,
  });

  final String categoryName;
  final List<TransactionModel> transactions;

  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required List<TransactionModel> transactions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryTransactionsSheet(
        categoryName: categoryName,
        transactions: transactions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final total = transactions.fold<double>(0, (m, t) => m + t.amount);
    return SafeArea(
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(categoryName,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.formatRupiah(total),
                  style: AppTypography.bodyBold
                      .copyWith(color: AppColors.primaryLight),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.historyCount(transactions.length),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final tx = transactions[i];
                  final d = DateTime.fromMillisecondsSinceEpoch(
                      tx.transactionDate);
                  return PressableScale(child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionDetailScreen(transaction: tx),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.merchantName ??
                                      tx.notes ??
                                      categoryName,
                                  style: AppTypography.bodyBold
                                      .copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatDayMonth(d),
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.formatRupiah(tx.amount),
                            style: AppTypography.bodyBold.copyWith(
                              color: tx.type == 'EXPENSE'
                                  ? AppColors.error
                                  : AppColors.statusPositive,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.onSurfaceVariant, size: 18),
                        ],
                      ),
                    ),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
