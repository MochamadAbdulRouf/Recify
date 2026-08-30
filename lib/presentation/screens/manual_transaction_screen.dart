import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
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
    final isExpense = _transactionType == 'EXPENSE';
    final amountColor = isExpense ? AppColors.error : AppColors.secondary;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Catat Transaksi Manual',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Large Amount Hero Card (Red for Expense, Emerald for Income)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceElevated.withValues(alpha: 0.7),
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
              child: Column(
                children: [
                  // Currency & Transaction Type Switcher Pill
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = isExpense ? 'INCOME' : 'EXPENSE';
                        final matching = financeProvider.categories.where((c) => c.type == _transactionType);
                        if (matching.isNotEmpty) {
                          _selectedCategory = matching.first;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
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
                            isExpense ? 'IDR • Pengeluaran' : 'IDR • Pemasukan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Large Display Numeric Input (Red for Expense, Emerald for Income)
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

            // 2. Horizontal Scrollable Category Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kategori Transaksi', style: AppTypography.titleSm),
                Text(
                  'Geser untuk pilih',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategoryHorizontalList(financeProvider),

            const SizedBox(height: 20),

            // 3. Transaction Name / Merchant Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Transaksi / Tempat',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: AppTypography.bodyLarge.copyWith(fontSize: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: isExpense
                          ? 'Contoh: Kopi Kenangan, Beli Bensin, Indomaret'
                          : 'Contoh: Gaji Bulanan, Bonus, Transfer Masuk',
                      hintStyle: AppTypography.bodyReg.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
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
            ),

            const SizedBox(height: 12),

            // 4. Date Card
            _buildActionCard(
              icon: Icons.calendar_today_rounded,
              label: 'Tanggal Transaksi',
              value: _formatDateLabel(_selectedDate),
              trailingIcon: Icons.chevron_right_rounded,
              onTap: _pickDate,
            ),

            const SizedBox(height: 12),

            // 5. Wallet Card
            _buildActionCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Dompet Pembayaran',
              value: _selectedWallet?.name ?? 'Pilih Dompet',
              trailingIcon: Icons.expand_more_rounded,
              onTap: () => _showWalletPicker(financeProvider),
            ),

            const SizedBox(height: 12),

            // 6. Notes Input Card (Optional)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Tambahan (Opsional)',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: AppTypography.bodyReg.copyWith(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Keterangan atau rincian item...',
                      hintStyle: AppTypography.bodyReg.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
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
            ),

            const SizedBox(height: 32),

            // 7. Bottom Action CTAs
            Row(
              children: [
                // Cancel
                Expanded(
                  flex: 1,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save CTA
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
                          'Simpan Transaksi',
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
    );
  }

  Widget _buildCategoryHorizontalList(FinanceProvider provider) {
    final categories = provider.categories.where((c) => c.type == _transactionType).toList();

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
              child: Container(
                width: 86,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceContainerHigh : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.borderMedium : AppColors.borderSubtle,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.bgSurfaceElevated,
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
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
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
                      color: AppColors.textSecondary,
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

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hari ini, ${DateFormat('d MMM').format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day) {
      return 'Kemarin, ${DateFormat('d MMM').format(date)}';
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
              surface: AppColors.bgSurface,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pilih Dompet / Sumber Dana', style: AppTypography.titleMedium),
                const SizedBox(height: 14),
                ...provider.wallets.map((w) {
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight),
                    title: Text(w.name, style: AppTypography.bodyBold),
                    subtitle: Text(
                      'Saldo: ${CurrencyFormatter.formatRupiah(w.currentBalance)}',
                      style: AppTypography.caption,
                    ),
                    trailing: _selectedWallet?.id == w.id
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary)
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
    // Clean string by removing dot separators
    final cleanDigits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanDigits) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transaksi yang valid')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan dompet transaksi')),
      );
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
          backgroundColor: AppColors.bgSurfaceElevated,
          content: Text(
            'Transaksi "$merchantName" sebesar ${CurrencyFormatter.formatRupiah(amount)} berhasil disimpan!',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
