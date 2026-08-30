import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'INCOME';
    final amountText = (isIncome ? '+' : '-') + CurrencyFormatter.formatRupiah(transaction.amount);
    final dateStr = DateFormatter.formatRelative(transaction.transactionDate);

    // Icon & Color styling based on category
    final categoryName = transaction.category?.name ?? 'Umum';
    IconData categoryIcon = Icons.receipt_long_rounded;
    Color iconColor = AppColors.primaryLight;
    Color iconBg = AppColors.primary.withValues(alpha: 0.12);

    if (isIncome) {
      categoryIcon = Icons.arrow_downward_rounded;
      iconColor = AppColors.secondary;
      iconBg = AppColors.statusPositiveBg;
    } else if (categoryName.toLowerCase().contains('makan') || categoryName.toLowerCase().contains('food')) {
      categoryIcon = Icons.restaurant_rounded;
      iconColor = AppColors.meshViolet;
      iconBg = AppColors.meshViolet.withValues(alpha: 0.15);
    } else if (categoryName.toLowerCase().contains('belanja') || categoryName.toLowerCase().contains('shop')) {
      categoryIcon = Icons.shopping_bag_rounded;
      iconColor = AppColors.meshCyan;
      iconBg = AppColors.meshCyan.withValues(alpha: 0.15);
    } else if (categoryName.toLowerCase().contains('tagihan') || categoryName.toLowerCase().contains('listrik')) {
      categoryIcon = Icons.bolt_rounded;
      iconColor = AppColors.primaryLight;
      iconBg = AppColors.primary.withValues(alpha: 0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: iconColor, size: 20),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchantName ?? transaction.category?.name ?? 'Transaksi',
                        style: AppTypography.bodyBold.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$categoryName • $dateStr',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount
                Text(
                  amountText,
                  style: AppTypography.bodyBold.copyWith(
                    color: isIncome ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
