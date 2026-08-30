import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

class BudgetProgressBar extends StatelessWidget {
  final String categoryName;
  final double spentAmount;
  final double budgetLimit;

  const BudgetProgressBar({
    super.key,
    required this.categoryName,
    required this.spentAmount,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = budgetLimit > 0 ? (spentAmount / budgetLimit).clamp(0.0, 1.5) : 0.0;
    final double progressClamped = percentage.clamp(0.0, 1.0);

    Color progressColor = AppColors.statusPositive;
    if (percentage >= 1.0) {
      progressColor = AppColors.statusNegative;
    } else if (percentage >= 0.8) {
      progressColor = AppColors.statusWarning;
    }

    final formattedSpent = CurrencyFormatter.format(spentAmount);
    final formattedLimit = CurrencyFormatter.format(budgetLimit);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                categoryName,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: AppTypography.labelMedium.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Track Bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressClamped,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: $formattedSpent',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Limit: $formattedLimit',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
