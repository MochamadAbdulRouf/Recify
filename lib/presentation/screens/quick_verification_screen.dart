import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/parsed_receipt_data.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../providers/finance_provider.dart';
import '../providers/scanner_provider.dart';

class QuickVerificationScreen extends StatefulWidget {
  final ParsedReceiptData parsedData;
  final String? receiptImagePath;

  const QuickVerificationScreen({
    super.key,
    required this.parsedData,
    this.receiptImagePath,
  });

  @override
  State<QuickVerificationScreen> createState() => _QuickVerificationScreenState();
}

class _QuickVerificationScreenState extends State<QuickVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  CategoryModel? _selectedCategory;
  WalletModel? _selectedWallet;
  late List<ParsedReceiptItem> _editableItems;

  late AnimationController _scannerAnimationController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedData.merchantName.isNotEmpty ? widget.parsedData.merchantName : 'Toko Retail',
    );
    _amountController = TextEditingController(text: widget.parsedData.grandTotal.toInt().toString());
    _notesController = TextEditingController(text: 'OCR Scan Nota');
    _selectedDate = widget.parsedData.transactionDate;
    _editableItems = List.from(widget.parsedData.items);

    // Laser scan animation
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(
        parent: _scannerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financeProvider = context.read<FinanceProvider>();
      if (financeProvider.categories.isNotEmpty) {
        // Match by category ID (suggestedCategory contains ID like 'cat_groceries')
        final guessed = financeProvider.categories.firstWhere(
          (c) => c.id == widget.parsedData.suggestedCategory,
          orElse: () => financeProvider.categories.firstWhere(
            (c) => c.type == 'EXPENSE',
            orElse: () => financeProvider.categories.first,
          ),
        );
        setState(() {
          _selectedCategory = guessed;
          if (financeProvider.wallets.isNotEmpty) {
            _selectedWallet = financeProvider.wallets.first;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _scannerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Receipt Preview Area with Animated Scan Beam
                _buildReceiptPreviewHero(),

                // 2. Verification Form Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          'Verify Details',
                          style: AppTypography.displayLgMobile,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Review extracted data before saving.',
                          style: AppTypography.bodyReg.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Form Input Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount & Date in 2 columns
                        Row(
                          children: [
                            // Amount Field
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AMOUNT',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Rp ',
                                          style: AppTypography.titleSm.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _amountController,
                                            keyboardType: TextInputType.number,
                                            style: AppTypography.headlineMd.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Date Field
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DATE',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              DateFormat('d MMM yyyy').format(_selectedDate),
                                              style: AppTypography.bodyBold.copyWith(fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Merchant / Toko Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MERCHANT / STORE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _merchantController,
                                style: AppTypography.bodyBold,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Nama Toko (e.g. Indomaret, Starbucks)',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Category Dropdown Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORY',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<CategoryModel>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  dropdownColor: AppColors.bgSurfaceElevated,
                                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                                  items: financeProvider.categories.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.meshViolet.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.label_rounded,
                                              size: 16,
                                              color: AppColors.meshViolet,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(c.name, style: AppTypography.bodyBold),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Wallet Selector Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAID FROM WALLET',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<WalletModel>(
                                  value: _selectedWallet,
                                  isExpanded: true,
                                  dropdownColor: AppColors.bgSurfaceElevated,
                                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                                  items: financeProvider.wallets.map((w) {
                                    return DropdownMenuItem(
                                      value: w,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.meshCyan),
                                          const SizedBox(width: 10),
                                          Text('${w.name} (${CurrencyFormatter.formatRupiah(w.currentBalance)})',
                                              style: AppTypography.bodyBold),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (w) => setState(() => _selectedWallet = w),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Itemized Breakdown Section
                        if (_editableItems.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text('Rincian Belanja (${_editableItems.length} item)', style: AppTypography.titleSm),
                          const SizedBox(height: 8),
                          ..._editableItems.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.itemName} (${item.quantity}x)',
                                      style: AppTypography.bodyReg.copyWith(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatRupiah(item.totalPrice),
                                    style: AppTypography.bodyBold.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 120), // Bottom padding for sticky action bar
              ],
            ),
          ),

          // 4. Fixed Bottom Action Bar matching Stitch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Close / Cancel Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Retake Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.bgSurfaceElevated,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.photo_camera_rounded, size: 18, color: AppColors.onSurface),
                        label: Text('Retake', style: AppTypography.bodyBold),
                        onPressed: _retakeReceipt,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Confirm Save Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 6,
                          shadowColor: const Color(0x662F6BFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'Confirm',
                          style: AppTypography.bodyBold.copyWith(color: Colors.white),
                        ),
                        onPressed: _saveTransaction,
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

  Widget _buildReceiptPreviewHero() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image / Receipt photo
          if (widget.receiptImagePath != null && File(widget.receiptImagePath!).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Image.file(
                File(widget.receiptImagePath!),
                fit: BoxFit.cover,
                color: const Color(0x99000000),
                colorBlendMode: BlendMode.darken,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF161824), Color(0xFF0F1018)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.receipt_rounded, size: 80, color: Color(0x33FFFFFF)),
              ),
            ),

          // Animated Laser Scanner Beam
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Positioned(
                top: 280 * _scannerAnimation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xCC2F6BFF),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Live OCR Status Badge at bottom right
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceElevated.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryFixed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryFixed,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OCR ACTIVE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryFixed,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  void _retakeReceipt() async {
    final scannerProvider = context.read<ScannerProvider>();
    await scannerProvider.pickAndScanReceipt(ImageSource.camera);
    if (mounted && scannerProvider.lastScanResult != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuickVerificationScreen(
            parsedData: scannerProvider.lastScanResult!,
            receiptImagePath: scannerProvider.scannedReceiptImagePath,
          ),
        ),
      );
    }
  }

  void _saveTransaction() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0!')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
      );
      return;
    }
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet/wallet terlebih dahulu!')),
      );
      return;
    }

    try {
      final txId = const Uuid().v4();
      final tx = TransactionModel(
        id: txId,
        walletId: _selectedWallet!.id,
        categoryId: _selectedCategory!.id,
        amount: amount,
        type: 'EXPENSE',
        merchantName: _merchantController.text.trim(),
        receiptImagePath: widget.receiptImagePath,
        transactionDate: _selectedDate.millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Scan Nota: ${_merchantController.text.trim()}',
      );

      final items = _editableItems.map((i) {
        return TransactionItemModel(
          id: const Uuid().v4(),
          transactionId: txId,
          itemName: i.itemName,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          totalPrice: i.totalPrice,
          categoryId: _selectedCategory!.id,
        );
      }).toList();

      final financeProvider = context.read<FinanceProvider>();
      await financeProvider.saveTransaction(tx, items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bgSurfaceElevated,
            content: Text(
              'Transaksi ${_merchantController.text} sebesar ${CurrencyFormatter.formatRupiah(amount)} tersimpan!',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to signal successful save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(
              'Gagal menyimpan transaksi: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}
