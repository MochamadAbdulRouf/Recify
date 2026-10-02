import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/parsed_receipt_data.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../components/app_toast.dart';
import '../components/glass_panel.dart';
import '../providers/finance_provider.dart';
import '../providers/scanner_provider.dart';
import '../components/pressable.dart';

class QuickVerificationScreen extends StatefulWidget {
  final ParsedReceiptData parsedData;
  final String? receiptImagePath;

  const QuickVerificationScreen({
    super.key,
    required this.parsedData,
    this.receiptImagePath,
  });

  @override
  State<QuickVerificationScreen> createState() =>
      _QuickVerificationScreenState();
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

  /// Nota lebih tua dari ini → dialog pilih hari ini / tanggal nota.
  static const _staleDateThresholdDays = 7;
  bool _staleDateDialogShown = false;

  late AnimationController _scannerAnimationController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedData.merchantName.isNotEmpty
          ? widget.parsedData.merchantName
          : 'Toko Retail',
    );
    _amountController = TextEditingController(
        text: widget.parsedData.grandTotal.toInt().toString());
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
      _validateReceiptDate();
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
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          // Header mengambang ala Stitch: back + judul (menggantikan
          // tombol close di bottom bar).
          Positioned(top: 0, left: 0, right: 0, child: _buildTopHeader()),
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Receipt Preview Area with Animated Scan Beam
                _buildReceiptPreviewHero(),

                // 2. Validation Status Badge & Parser Source
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _buildValidationBadge(),
                ),

                // 3. Form Input Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassPanel(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header kartu ala Stitch: ikon + judul + perisai
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.document_scanner_outlined,
                                  size: 20, color: AppColors.primaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.verifyDetails,
                                      style: AppTypography.titleMedium),
                                  Text(s.reviewExtracted,
                                      style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceContainerHighest,
                              ),
                              child: Icon(Icons.verified_user_outlined,
                                  size: 18, color: AppColors.statusPositive),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Total pill (posisi Detected Total di desain Stitch)
                        // — nilai tetap bisa diedit, sumber amount untuk save
                        // tidak berubah.
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest
                                .withValues(alpha: 0.8),
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
                                      s.fieldAmount,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Rp ',
                                          style: AppTypography.titleSm.copyWith(
                                              color: AppColors.textSecondary),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _amountController,
                                            keyboardType:
                                                TextInputType.number,
                                            style: AppTypography
                                                .displayLgMobile
                                                .copyWith(
                                                    color:
                                                        AppColors.textPrimary),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    s.taxIncluded,
                                    style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.formatRupiah(
                                        widget.parsedData.tax),
                                    style: AppTypography.labelLarge
                                        .copyWith(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Field rows ala Stitch: ikon + label + nilai + aksi
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldRow(
                              icon: Icons.calendar_today_outlined,
                              iconColor: AppColors.meshCyan,
                              label: s.fieldDate,
                              onTap: _pickDate,
                              child: Text(
                                DateFormat('d MMM yyyy')
                                    .format(_selectedDate),
                                style: AppTypography.titleSm,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.schedule_rounded,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant),
                            ),

                            // Stale date warning — receipt date differs from today,
                            // transaction will not appear in current-month recap
                            if (!_isDateToday) ...[
                              const SizedBox(height: 10),
                              _buildStaleDateWarning(),
                            ],

                            const SizedBox(height: 12),

                            // Merchant — tetap TextField (editabel), gaya row
                            _fieldRow(
                              icon: Icons.storefront_outlined,
                              iconColor: AppColors.primaryLight,
                              label: s.fieldMerchant,
                              child: TextField(
                                controller: _merchantController,
                                style: AppTypography.titleSm,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: s.merchantHint,
                                ),
                              ),
                              trailing: Icon(Icons.verified_rounded,
                                  size: 18, color: AppColors.statusPositive),
                            ),

                            const SizedBox(height: 12),

                            // Expense Category — dropdown sebagai baris,
                            // tertutup: nama + tag + "Change ⌄" (al Stitch)
                            _fieldRow(
                              icon: Icons.restaurant_rounded,
                              iconColor: AppColors.textSecondary,
                              label: s.fieldCategory,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<CategoryModel>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  isDense: true,
                                  dropdownColor:
                                      AppColors.surfaceContainerHigh,
                                  icon: const SizedBox.shrink(),
                                  selectedItemBuilder: (ctx) =>
                                      financeProvider.categories.map((c) {
                                    final auto = c.id ==
                                        widget.parsedData.suggestedCategory;
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.name,
                                            style: AppTypography.titleSm,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (auto) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors
                                                  .statusPositiveBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              s.autoMapped,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColors.statusPositive,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Text(
                                          s.change,
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                                  color:
                                                      AppColors.primaryLight),
                                        ),
                                        Icon(Icons.expand_more_rounded,
                                            size: 18,
                                            color: AppColors.primaryLight),
                                      ],
                                    );
                                  }).toList(),
                                  items:
                                      financeProvider.categories.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.meshViolet
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.label_rounded,
                                              size: 16,
                                              color: AppColors.meshViolet,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(c.name,
                                              style: AppTypography.bodyBold),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (cat) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Payment Wallet — dropdown sebagai baris (swap)
                            _fieldRow(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.meshCyan,
                              label: s.fieldWallet,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<WalletModel>(
                                  value: _selectedWallet,
                                  isExpanded: true,
                                  isDense: true,
                                  dropdownColor:
                                      AppColors.surfaceContainerHigh,
                                  icon: const SizedBox.shrink(),
                                  selectedItemBuilder: (ctx) =>
                                      financeProvider.wallets.map((w) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            w.name,
                                            style: AppTypography.titleSm,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          CurrencyFormatter.formatRupiah(
                                              w.currentBalance),
                                          style: AppTypography.caption
                                              .copyWith(
                                                  color: AppColors
                                                      .textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.swap_horiz_rounded,
                                            size: 18,
                                            color: AppColors.primaryLight),
                                      ],
                                    );
                                  }).toList(),
                                  items: financeProvider.wallets.map((w) {
                                    return DropdownMenuItem(
                                      value: w,
                                      child: Row(
                                        children: [
                                          Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              size: 18,
                                              color: AppColors.meshCyan),
                                          const SizedBox(width: 10),
                                          Text(
                                              '${w.name} (${CurrencyFormatter.formatRupiah(w.currentBalance)})',
                                              style: AppTypography.bodyBold),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (w) =>
                                      setState(() => _selectedWallet = w),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Itemized breakdown box (al Stitch)
                        if (_editableItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.receiptItems(_editableItems.length),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    Text(
                                      widget.parsedData.parserSource == 'gemini'
                                          ? s.parserGemini
                                          : s.parserOffline,
                                      style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.primaryLight),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._editableItems.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.itemName} (${item.quantity}x)',
                                            style: AppTypography.caption,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          CurrencyFormatter.formatRupiah(
                                              item.totalPrice),
                                          style: AppTypography.bodyBold
                                              .copyWith(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Tombol aksi di dalam kartu (al Stitch)
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: PressableScale(child: GestureDetector(
                                onTap: _retakeReceipt,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.refresh_rounded,
                                          size: 18,
                                          color: AppColors.textPrimary),
                                      const SizedBox(width: 6),
                                      Text(s.retake,
                                          style: AppTypography.titleSm),
                                    ],
                                  ),
                                ),
                              )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: PressableScale(child: GestureDetector(
                                onTap: _saveTransaction,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        s.confirmAndSave,
                                        style: AppTypography.titleSm
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge enkripsi lokal (al Stitch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.statusPositive),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.encryptedBadge,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

        ],
      ),
    );
  }

  /// Header mengambang (al Stitch): back + judul, blur tipis di atas konten.
  Widget _buildTopHeader() {
    final s = AppStrings.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.bgCanvas.withValues(alpha: 0.80),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(s.scanAndPay, style: AppTypography.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Baris field seragam (al Stitch): chip ikon 40 + label uppercase + nilai
  /// + trailing; opsional onTap untuk seluruh baris.
  Widget _fieldRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return PressableScale(child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    ));
  }

  Widget _buildValidationBadge() {
    final s = AppStrings.of(context);
    final scannerProvider = context.watch<ScannerProvider>();
    final validationResult = scannerProvider.validationResult;
    final parserSource = widget.parsedData.parserSource;

    // Determine parser source label
    final String parserLabel;
    final IconData parserIcon;
    if (parserSource == 'gemini') {
      parserLabel = s.parserGemini;
      parserIcon = Icons.auto_awesome_rounded;
    } else {
      parserLabel = s.parserOffline;
      parserIcon = Icons.offline_bolt_rounded;
    }

    // Determine validation status
    final String statusLabel;
    final Color statusColor;
    final IconData statusIcon;
    if (validationResult == null) {
      statusLabel = s.statusNotValidated;
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.help_outline_rounded;
    } else {
      switch (validationResult.status) {
        case 'valid':
          statusLabel = s.statusValid;
          statusColor = const Color(0xFF4ADE80); // green-400
          statusIcon = Icons.check_circle_rounded;
          break;
        case 'warning':
          statusLabel = s.statusCheck;
          statusColor = const Color(0xFFFBBF24); // amber-400
          statusIcon = Icons.warning_amber_rounded;
          break;
        default: // 'needs_review'
          statusLabel = s.statusNeedsReview;
          statusColor = const Color(0xFFF87171); // red-400
          statusIcon = Icons.error_outline_rounded;
          break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Parser Source Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(parserIcon, size: 14, color: AppColors.meshCyan),
              const SizedBox(width: 5),
              Text(
                parserLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.meshCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Validation Status Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 5),
              Text(
                statusLabel,
                style: AppTypography.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPreviewHero() {
    final s = AppStrings.of(context);
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image / Receipt photo
          if (widget.receiptImagePath != null &&
              File(widget.receiptImagePath!).existsSync())
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
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
                child: Icon(Icons.receipt_rounded,
                    size: 80, color: Color(0x33FFFFFF)),
              ),
            ),

          // Grid scanner geometris (al Stitch) — warna dari token primary
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerGridPainter(
                AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Vignette atas-bawah
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceContainerLowest.withValues(alpha: 0.70),
                    Colors.transparent,
                    AppColors.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),

          // Animated Laser Scanner Beam (cyan al Stitch)
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Positioned(
                top: 280 * _scannerAnimation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.meshCyan,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.meshCyan.withValues(alpha: 0.8),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Target reticle corners (al Stitch)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.crop_free_rounded,
                        size: 26,
                        color: AppColors.meshCyan.withValues(alpha: 0.7)),
                    Transform.flip(
                      flipX: true,
                      child: Icon(Icons.crop_free_rounded,
                          size: 26,
                          color: AppColors.meshCyan.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.flip(
                      flipY: true,
                      child: Icon(Icons.crop_free_rounded,
                          size: 26,
                          color: AppColors.meshCyan.withValues(alpha: 0.7)),
                    ),
                    Transform.flip(
                      flipX: true,
                      flipY: true,
                      child: Icon(Icons.crop_free_rounded,
                          size: 26,
                          color: AppColors.meshCyan.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top meta pills: OCR ACTIVE • ON-DEVICE + 100% PRIVATE
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest
                        .withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.statusPositive,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.ocrActiveDevice,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.statusPositive,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest
                        .withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 12, color: AppColors.secondaryFixed),
                      const SizedBox(width: 4),
                      Text(
                        s.hundredPrivate,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Retake pill di pojok kanan bawah (al Stitch: slot Adjust Box,
          // dipetakan ke logika retake yang sudah ada)
          Positioned(
            bottom: 12,
            right: 12,
            child: PressableScale(child: GestureDetector(
              onTap: _retakeReceipt,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh
                      .withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      s.retake,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  bool get _isDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _daysAgoLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final days = today.difference(thatDay).inDays;
    final s = AppStrings.of(context);
    if (days == 1) return s.yesterday.toLowerCase();
    if (days < 31) return s.daysAgo(days);
    return s.monthsAgo((days / 30.44).round());
  }

  Widget _buildStaleDateWarning() {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat_rounded,
              size: 18, color: Color(0xFFFBBF24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.staleDateWarning(
                DateFormat('d MMM yyyy').format(_selectedDate),
                _daysAgoLabel(_selectedDate),
              ),
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFFBBF24),
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(child: GestureDetector(
            onTap: () => setState(() => _selectedDate = DateTime.now()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.useToday,
                style: AppTypography.caption.copyWith(
                  color: const Color(0xFFFBBF24),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// Validasi tanggal nota setelah scan:
  /// - tak terbaca/tidak valid (dateFallback) → paksa hari ini + toast;
  /// - masa depan → paksa hari ini + toast;
  /// - lebih dari 7 hari → dialog: pakai tanggal hari ini / tanggal nota.
  void _validateReceiptDate() {
    if (!mounted) return;
    final s = AppStrings.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.parsedData.dateFallback) {
      setState(() => _selectedDate = today);
      AppToast.error(s.dateUnreadableNotice);
      return;
    }

    final d = _selectedDate;
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly.isAfter(today)) {
      setState(() => _selectedDate = today);
      AppToast.error(s.dateFutureNotice);
      return;
    }

    if (today.difference(dateOnly).inDays > _staleDateThresholdDays) {
      _showStaleDateDialog();
    }
  }

  Future<void> _showStaleDateDialog() async {
    if (_staleDateDialogShown || !mounted) return;
    _staleDateDialogShown = true;
    final s = AppStrings.of(context);
    final receiptDate = DateFormat('d MMM yyyy').format(_selectedDate);

    final useToday = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.dateOldTitle, style: AppTypography.titleMedium),
        content: Text(
          s.staleDateWarning(receiptDate, _daysAgoLabel(_selectedDate)),
          style: AppTypography.bodyReg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.useReceiptDate(receiptDate),
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.useToday,
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );

    if (useToday == true && mounted) {
      setState(() => _selectedDate = DateTime.now());
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      // Tanpa wrapper ThemeData.dark() hardcode — ikut tema aktif
      // (light/dark), permukaan & teks dialog selalu konsisten.
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
    final s = AppStrings.of(context);
    final amount = double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;
    if (amount <= 0) {
      AppToast.error(s.errAmountZero);
      return;
    }
    if (_selectedCategory == null) {
      AppToast.error(s.errPickCategory);
      return;
    }
    if (_selectedWallet == null) {
      AppToast.error(s.errPickWallet);
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
        AppToast.success(
          s.savedScan(
            _merchantController.text,
            CurrencyFormatter.formatRupiah(amount),
          ),
        );
        Navigator.pop(context, true); // Return true to signal successful save
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(s.saveFailed('$e'));
      }
    }
  }
}

/// Grid scanner geometris untuk preview nota (al Stitch) — 24px, warna token.
class _ScannerGridPainter extends CustomPainter {
  _ScannerGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
