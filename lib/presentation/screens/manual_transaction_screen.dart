import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../components/glass_panel.dart';
import '../providers/finance_provider.dart';

class ManualTransactionScreen extends StatefulWidget {
  const ManualTransactionScreen({super.key});

  @override
  State<ManualTransactionScreen> createState() => _ManualTransactionScreenState();
}

class _ManualTransactionScreenState extends State<ManualTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  WalletModel? _selectedWallet;
  String _transactionType = 'EXPENSE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financeProvider = context.read<FinanceProvider>();
      if (financeProvider.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = financeProvider.categories.firstWhere(
            (c) => c.type == _transactionType,
            orElse: () => financeProvider.categories.first,
          );
        });
      }
      if (financeProvider.wallets.isNotEmpty) {
        setState(() {
          _selectedWallet = financeProvider.wallets.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);
    final isExpense = _transactionType == 'EXPENSE';
    final amountColor = isExpense ? AppColors.error : AppColors.secondary;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          s.manualEntryTitle,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Amount hero — glass with the v2 gradient
                GlassPanel(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  fill: AppColors.heroCardGradient,
                  glowBlobs: true,
                  child: Column(
                    children: [
                      // Currency + type switcher
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _transactionType = isExpense ? 'INCOME' : 'EXPENSE';
                            final matching = financeProvider.categories
                                .where((c) => c.type == _transactionType);
                            if (matching.isNotEmpty) {
                              _selectedCategory = matching.first;
                            }
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withValues(alpha: 0.80),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: amountColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpense ? s.typeExpense : s.typeIncome,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.expand_more_rounded,
                                      size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Large numeric input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Rp',
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 32,
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                style: AppTypography.displayLg.copyWith(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.0,
                                  color: amountColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: AppTypography.displayLg.copyWith(
                                    fontSize: 48,
                                    color: amountColor.withValues(alpha: 0.35),
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 2. Category carousel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.categorySectionTitle, style: AppTypography.titleSm),
                    Text(
                      s.swipeToPick,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCategoryHorizontalList(financeProvider),

                const SizedBox(height: 20),

                // 3. Merchant name input
                _buildInputCard(
                  label: s.nameLabel,
                  hint: isExpense ? s.nameHintExpense : s.nameHintIncome,
                  controller: _titleController,
                  style: AppTypography.bodyLarge
                      .copyWith(fontSize: 15, color: AppColors.textPrimary),
                  hintStyle: AppTypography.bodyReg
                      .copyWith(color: AppColors.textMuted, fontSize: 14),
                ),

                const SizedBox(height: 12),

                // 4. Date
                _buildActionCard(
                  icon: Icons.calendar_today_rounded,
                  label: s.dateLabel,
                  value: _formatDateLabel(_selectedDate, s),
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _pickDate,
                ),

                const SizedBox(height: 12),

                // 5. Wallet
                _buildActionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: s.walletLabel,
                  value: _selectedWallet?.name ?? s.chooseWallet,
                  trailingIcon: Icons.expand_more_rounded,
                  onTap: () => _showWalletPicker(financeProvider),
                ),

                const SizedBox(height: 12),

                // 6. Notes
                _buildInputCard(
                  label: s.notesLabel,
                  hint: s.notesHint,
                  controller: _notesController,
                  style: AppTypography.bodyReg
                      .copyWith(fontSize: 14, color: AppColors.textPrimary),
                  hintStyle: AppTypography.bodyReg
                      .copyWith(color: AppColors.textMuted, fontSize: 14),
                ),

                const SizedBox(height: 32),

                // 7. CTAs
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          s.cancel,
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _saveTransaction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryCtaGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              s.saveTransaction,
                              style: AppTypography.bodyBold.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextStyle style,
    required TextStyle hintStyle,
  }) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: style,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: hintStyle,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHorizontalList(FinanceProvider provider) {
    final categories =
        provider.categories.where((c) => c.type == _transactionType).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory?.id == cat.id;
          final iconData = _getCategoryIcon(cat.name);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surfaceContainerHigh.withValues(alpha: 0.90)
                          : AppColors.surfaceContainerLow.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.borderMedium
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 22,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('makan') || lower.contains('food') || lower.contains('kuliner')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('transport') || lower.contains('bensin') || lower.contains('kendaraan')) {
      return Icons.directions_car_rounded;
    } else if (lower.contains('belanja') || lower.contains('shop') || lower.contains('pasar')) {
      return Icons.shopping_bag_rounded;
    } else if (lower.contains('tagihan') || lower.contains('listrik') || lower.contains('air') || lower.contains('pulsa')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('hiburan') || lower.contains('game') || lower.contains('nonton')) {
      return Icons.movie_rounded;
    } else if (lower.contains('kesehatan') || lower.contains('obat') || lower.contains('medis')) {
      return Icons.medical_services_rounded;
    } else if (lower.contains('pendidikan') || lower.contains('buku') || lower.contains('sekolah')) {
      return Icons.school_rounded;
    } else if (lower.contains('gaji') || lower.contains('salary')) {
      return Icons.payments_rounded;
    } else if (lower.contains('investasi') || lower.contains('crypto') || lower.contains('saham')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('bonus') || lower.contains('hadiah') || lower.contains('gift')) {
      return Icons.card_giftcard_rounded;
    }
    return Icons.category_rounded;
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String value,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(trailingIcon, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final time = DateFormat('d MMM').format(date);
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return s.todayLabel(time);
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day) {
      return s.yesterdayLabel(time);
    }
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceContainerLow,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showWalletPicker(FinanceProvider provider) {
    final s = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.selectWalletTitle, style: AppTypography.titleMedium),
                const SizedBox(height: 14),
                ...provider.wallets.map((w) {
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColors.primaryLight),
                    title: Text(w.name, style: AppTypography.bodyBold),
                    subtitle: Text(
                      '${s.balanceLabel}: ${CurrencyFormatter.formatRupiah(w.currentBalance)}',
                      style: AppTypography.caption,
                    ),
                    trailing: _selectedWallet?.id == w.id
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.secondary)
                        : null,
                    onTap: () {
                      setState(() => _selectedWallet = w);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveTransaction() async {
    final s = AppStrings.of(context);
    final cleanDigits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanDigits) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errAmount)));
      return;
    }

    if (_selectedCategory == null || _selectedWallet == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.errCategoryWallet)));
      return;
    }

    final titleText = _titleController.text.trim();
    final notesText = _notesController.text.trim();
    final merchantName = titleText.isNotEmpty ? titleText : _selectedCategory!.name;

    final tx = TransactionModel(
      id: const Uuid().v4(),
      walletId: _selectedWallet!.id,
      categoryId: _selectedCategory!.id,
      amount: amount,
      type: _transactionType,
      merchantName: merchantName,
      transactionDate: _selectedDate.millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      notes: notesText.isNotEmpty ? notesText : 'Catat manual: $merchantName',
    );

    final financeProvider = context.read<FinanceProvider>();
    await financeProvider.saveTransaction(tx, []);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          content: Text(
            s.savedTransaction(merchantName, CurrencyFormatter.formatRupiah(amount)),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
