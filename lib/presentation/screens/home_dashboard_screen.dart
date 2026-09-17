import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../components/glass_panel.dart';
import '../components/obsidian_hero_card.dart';
import '../components/quick_action_grid.dart';
import '../components/scan_progress_dialog.dart';
import '../components/transaction_list_item.dart';
import '../providers/finance_provider.dart';
import '../providers/scanner_provider.dart';
import 'manual_transaction_screen.dart';
import 'quick_verification_screen.dart';
import 'transaction_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _userName = '';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await ProfileService.getUserName();
    final avatar = await ProfileService.getAvatarPath();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _avatarPath = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final scannerProvider = context.watch<ScannerProvider>();
    final s = AppStrings.of(context);
    final firstName = _userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Fixed / Sticky Frosted Header
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  toolbarHeight: 68,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCanvas.withValues(alpha: 0.60),
                          border: const Border(
                            bottom: BorderSide(
                                color: AppColors.borderSubtle, width: 1.0),
                          ),
                        ),
                        padding:
                            const EdgeInsets.only(left: 24, right: 24, top: 28),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Avatar + greeting (v2)
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceContainerHigh,
                                      border: Border.all(
                                          color: AppColors.borderMedium),
                                      image: _avatarPath != null &&
                                              File(_avatarPath!).existsSync()
                                          ? DecorationImage(
                                              image:
                                                  FileImage(File(_avatarPath!)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: _avatarPath != null &&
                                            File(_avatarPath!).existsSync()
                                        ? null
                                        : Text(
                                            firstName.isEmpty
                                                ? '?'
                                                : firstName[0].toUpperCase(),
                                            style:
                                                AppTypography.bodyBold.copyWith(
                                              color: AppColors.primaryLight,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.greetingFor(DateTime.now().hour),
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          firstName.isEmpty
                                              ? 'Recify'
                                              : firstName,
                                          style: AppTypography.headlineMd
                                              .copyWith(fontSize: 19),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quick Settings / Profile Trigger
                            GestureDetector(
                              onTap: () => widget.onNavigateTab?.call(3),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderSubtle),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Obsidian Hero Card (Real Metrics)
                      ObsidianHeroCard(
                        totalBalance: financeProvider.totalBalance,
                        monthlyIncome: financeProvider.monthlyIncome,
                        monthlyExpense: financeProvider.monthlyExpense,
                      ),

                      const SizedBox(height: 20),

                      // 2. High-Agency Action Hub
                      QuickActionGrid(
                        onScanReceipt: () =>
                            _handleScanReceipt(context, scannerProvider),
                        onManualExpense: () => _showManualEntry(context),
                        onExportCsv: () => _handleExportCsv(context),
                      ),

                      const SizedBox(height: 28),

                      // 3. Section Header: Aktivitas Terbaru
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.recentActivity, style: AppTypography.titleSm),
                          if (financeProvider.recentTransactions.isNotEmpty)
                            GestureDetector(
                              onTap: () => widget.onNavigateTab
                                  ?.call(2), // Jump to History
                              child: Text(
                                s.viewAll,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 4. Recent Transactions List
                      if (financeProvider.recentTransactions.isEmpty)
                        _buildEmptyState(context, scannerProvider)
                      else
                        ...financeProvider.recentTransactions.take(6).map((tx) {
                          return TransactionListItem(
                            transaction: tx,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionDetailScreen(transaction: tx),
                                ),
                              );
                            },
                          );
                        }),

                      const SizedBox(
                          height: 132), // Space for Floating Island + FAB
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ScannerProvider scannerProvider) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 32, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            s.noTransactionsYet,
            style:
                AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            s.noTransactionsHint,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.camera_alt_outlined,
                size: 16, color: AppColors.primaryLight),
            label: Text(s.startScan,
                style: AppTypography.caption
                    .copyWith(color: AppColors.primaryLight)),
            onPressed: () => _handleScanReceipt(context, scannerProvider),
          ),
        ],
      ),
    );
  }

  void _handleScanReceipt(
      BuildContext context, ScannerProvider scannerProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(AppStrings.of(ctx).chooseSource,
                    style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primaryLight),
                  ),
                  title: Text(AppStrings.of(ctx).cameraOption,
                      style: AppTypography.bodyBold),
                  subtitle: Text(AppStrings.of(ctx).cameraOptionHint,
                      style: AppTypography.caption),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _scanWithProgress(
                        context, scannerProvider, ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.secondary),
                  ),
                  title: Text(AppStrings.of(ctx).galleryOption,
                      style: AppTypography.bodyBold),
                  subtitle: Text(AppStrings.of(ctx).receiptImageSaved,
                      style: AppTypography.caption),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _scanWithProgress(
                        context, scannerProvider, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Opens the live progress dialog, runs the scan pipeline, closes the
  /// dialog, then navigates to verification on success.
  Future<void> _scanWithProgress(
    BuildContext context,
    ScannerProvider scannerProvider,
    ImageSource source,
  ) async {
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const ScanProgressDialog(),
    ));

    await scannerProvider.pickAndScanReceipt(source);

    if (context.mounted) {
      // Close the progress dialog (safe even if already closed).
      Navigator.of(context, rootNavigator: true).pop();
      if (scannerProvider.lastScanResult != null) {
        Navigator.push(
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
  }

  void _showManualEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualTransactionScreen(),
      ),
    );
  }

  void _handleExportCsv(BuildContext context) async {
    final financeProvider = context.read<FinanceProvider>();
    try {
      final path = await financeProvider.exportCsvFile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bgSurfaceElevated,
            content: Text('${AppStrings.of(context).reportSaved}$path',
                style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.of(context).exportFailed}$e')),
        );
      }
    }
  }
}
