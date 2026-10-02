import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/wallet_model.dart';
import '../components/app_toast.dart';
import '../components/budget_progress_bar.dart';
import '../components/glass_panel.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/scanner_provider.dart';
import '../providers/theme_provider.dart';
import '../../domain/backup/backup_manager.dart';
import '../components/pressable.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Pengguna Recify';
  String? _avatarPath;
  String _cacheSizeStr = '0.0 MB';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _calculateCacheSize();
  }

  Future<void> _loadProfile() async {
    final name = await ProfileService.getUserName();
    final avatar = await ProfileService.getAvatarPath();
    if (mounted) {
      setState(() {
        _userName = name;
        _avatarPath = avatar;
      });
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalBytes = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((file) {
          if (file is File) {
            totalBytes += file.lengthSync();
          }
        });
      }
      final double mb = totalBytes / (1024 * 1024);
      if (mounted) {
        setState(() {
          _cacheSizeStr = '${mb.toStringAsFixed(1)} MB';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeStr = '1.2 MB';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    final s = AppStrings.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((file) {
          if (file is File) {
            try {
              file.deleteSync();
            } catch (_) {}
          }
        });
      }
      await _calculateCacheSize();
      if (mounted) {
        AppToast.success(s.cacheCleared);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(s.cacheFailed(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      // Stitch Sticky Frosted Header
      appBar: StickyFrostedAppBar(
        height: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.profileSettings, style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              s.accountSecuritySubtitle,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // 1. Hero Profile Section with Ambient Glowing Aura (Stitch Design)
            PressableScale(child: GestureDetector(
              onTap: _showEditProfileSheet,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing Sapphire Ambient Aura
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),

                  // Avatar Container
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    ),
                    child: ClipOval(
                      child: _avatarPath != null && File(_avatarPath!).existsSync()
                          ? Image.file(
                              File(_avatarPath!),
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(Icons.person_rounded, size: 44, color: AppColors.primaryLight),
                            ),
                    ),
                  ),

                  // Edit Button Badge at bottom right
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 14),

            // Profile Name (Click to edit) & Security Badge
            PressableScale(child: GestureDetector(
              onTap: _showEditProfileSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName.isEmpty || _userName == 'Pengguna Recify'
                        ? s.userNameDefault
                        : _userName,
                    style: AppTypography.headlineMd.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                ],
              ),
            )),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                s.offlineNote,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),

            const SizedBox(height: 28),

            // 2. Section: Account & Security (Stitch Match)
            _buildSectionHeader(s.sectionAccountSecurity),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                title: s.manageWallets,
                subtitle: s.walletCountSubtitle(financeProvider.wallets.length),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatRupiah(financeProvider.totalBalance),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
                onTap: () => _showManageWalletsSheet(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.lock_rounded,
                iconColor: AppColors.secondary,
                title: s.securityData,
                subtitle: s.onDeviceProtection,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.activeStatus,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.payments_rounded,
                iconColor: AppColors.meshCyan,
                title: s.mainCurrency,
                subtitle: s.rupiahFormat,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.idrFormat,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // 3. Section: Data Management (Stitch Match)
            _buildSectionHeader(s.sectionDataManager),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.backup_rounded,
                iconColor: AppColors.meshCyan,
                title: s.localBackupRestore,
                subtitle: s.localBackupSubtitle,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () => _showBackupRestoreSheet(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.meshViolet,
                title: s.exportTransactions,
                subtitle: s.exportTransactionsSubtitle,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.meshViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Excel / CSV',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.meshViolet,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                onTap: () => _showExportDialog(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.delete_sweep_rounded,
                iconColor: AppColors.error,
                title: s.clearImageCache,
                subtitle: s.clearImageCacheSubtitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _cacheSizeStr,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
                onTap: _clearCache,
              ),
            ]),

            const SizedBox(height: 22),

            // 4. Section: Preferences (Stitch Match)
            _buildSectionHeader(s.sectionPrefsDisplay),
            _buildCardGroup([
              Builder(
                builder: (context) {
                  final theme = context.watch<ThemeProvider>();
                  final labels = [
                    s.themeSystem,
                    s.themeLight,
                    s.themeDark,
                  ];
                  final index = theme.mode == 'light'
                      ? 1
                      : theme.mode == 'dark'
                          ? 2
                          : 0;
                  final subtitle = theme.mode == 'light'
                      ? s.themeLightSubtitle
                      : theme.mode == 'dark'
                          ? s.themeDarkSubtitle
                          : s.themeSystemSubtitle;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSettingItem(
                        icon: Icons.brightness_6_rounded,
                        iconColor: AppColors.textPrimary,
                        title: s.themeSettings,
                        subtitle: subtitle,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: GlassSegmentedTabs(
                          labels: labels,
                          index: index,
                          onChanged: (i) => theme.setMode(
                            ['system', 'light', 'dark'][i],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.category_rounded,
                iconColor: AppColors.meshIndigo,
                title: s.ledgerCategories,
                subtitle:
                    s.categoryCountSubtitle(financeProvider.categories.length),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 18),
                onTap: () =>
                    _showManageCategoriesSheet(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.savings_rounded,
                iconColor: AppColors.statusWarning,
                title: s.monthlyBudget,
                subtitle: _budgetSubtitle(financeProvider),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 18),
                onTap: () => _showBudgetSheet(context, financeProvider),
              ),
            ]),

            const SizedBox(height: 22),

            // Section: Preferences (Language)
            _buildSectionHeader(s.sectionPrefs),
            _buildCardGroup([
              Builder(
                builder: (context) {
                  final locale = context.watch<LocaleProvider>();
                  final s = AppStrings.of(context);
                  return _buildSettingItem(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.meshCyan,
                    title: s.language,
                    subtitle: locale.isEn ? s.english : s.indonesian,
                    trailing: Switch.adaptive(
                      value: locale.isEn,
                      onChanged: (val) => locale.setLocale(val ? 'en' : 'id'),
                      activeTrackColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 22),

            // 5. Section: OCR & AI Parser
            _buildSectionHeader('OCR & AI PARSER'),
            _buildCardGroup([
              Builder(
                builder: (context) {
                  final scannerProvider = context.watch<ScannerProvider>();
                  return _buildSettingItem(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF8B5CF6), // violet-500
                    title: s.geminiAiParser,
                    subtitle: scannerProvider.useAiParser
                        ? s.geminiParserOn
                        : s.geminiParserOff,
                    trailing: Switch.adaptive(
                      value: scannerProvider.useAiParser,
                      onChanged: (val) => scannerProvider.setUseAiParser(val),
                      activeTrackColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _buildDivider(),
              Builder(
                builder: (context) {
                  final scannerProvider = context.watch<ScannerProvider>();
                  return _buildSettingItem(
                    icon: Icons.key_rounded,
                    iconColor: AppColors.meshCyan,
                    title: 'Gemini API Key',
                    subtitle: scannerProvider.hasApiKey
                        ? s.apiKeyStored
                        : s.notConfigured,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: scannerProvider.hasApiKey
                                ? AppColors.secondary.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scannerProvider.hasApiKey ? s.activeStatus : s.emptyStatus,
                            style: AppTypography.caption.copyWith(
                              color: scannerProvider.hasApiKey ? AppColors.secondary : AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                    onTap: () => _showApiKeyDialog(context),
                  );
                },
              ),
            ]),

            const SizedBox(height: 22),

            // 6. Section: Support & Info (Stitch Match)
            _buildSectionHeader(s.sectionHelpInfo),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.help_center_rounded,
                iconColor: AppColors.textSecondary,
                title: s.helpCenter,
                subtitle: s.helpCenterSubtitle,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(s.guideTitle, style: AppTypography.titleMedium),
                      content: Text(
                        s.guideBody,
                        style: AppTypography.bodyReg,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s.understood, style: TextStyle(color: AppColors.primaryLight)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.policy_rounded,
                iconColor: AppColors.textSecondary,
                title: s.privacyPolicy,
                subtitle: s.privacySubtitle,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(s.privacyPolicy, style: AppTypography.titleMedium),
                      content: Text(
                        s.privacyBody,
                        style: AppTypography.bodyReg,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s.closeButton, style: TextStyle(color: AppColors.primaryLight)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 18),

            // App Version Badge
            Text(
              s.versionLabel,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),

            const SizedBox(height: 100), // Space for Floating Island Navbar
          ],
        ),
      ),
    );
  }

  // --- 1. EDIT PROFILE BOTTOM SHEET ---
  void _showEditProfileSheet() {
    final s = AppStrings.of(context);
    final nameController = TextEditingController(
        text: _userName == 'Pengguna Recify' ? s.userNameDefault : _userName);
    String? tempAvatarPath = _avatarPath;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final s = AppStrings.of(context);
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
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
                    const SizedBox(height: 16),
                    Text(s.editUserProfile, style: AppTypography.titleMedium),
                    const SizedBox(height: 20),

                    // Avatar Preview
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                          ),
                          child: ClipOval(
                            child: tempAvatarPath != null && File(tempAvatarPath!).existsSync()
                                ? Image.file(
                                    File(tempAvatarPath!),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.person_rounded, size: 44, color: AppColors.primaryLight),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Photo source buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgSurfaceElevated,
                            foregroundColor: AppColors.primaryLight,
                            elevation: 0,
                            side: BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: Text(s.camera, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 85);
                            if (photo != null) {
                              setSheetState(() => tempAvatarPath = photo.path);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgSurfaceElevated,
                            foregroundColor: AppColors.secondary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 16),
                          label: Text(s.gallery, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final photo = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
                            if (photo != null) {
                              setSheetState(() => tempAvatarPath = photo.path);
                            }
                          },
                        ),
                        if (tempAvatarPath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                            onPressed: () => setSheetState(() => tempAvatarPath = null),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Name Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.usernameField, style: AppTypography.caption.copyWith(fontSize: 10, letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: nameController,
                            style: AppTypography.bodyBold.copyWith(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: s.usernameHint,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Profile CTA (Full-width Material Button with Instant Tap Response)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: PressableScale(child: InkWell(
                        onTap: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) return;

                                setSheetState(() => isSaving = true);
                                FocusScope.of(ctx).unfocus();

                                try {
                                  String? finalPath = tempAvatarPath;
                                  if (tempAvatarPath != null && File(tempAvatarPath!).existsSync()) {
                                    try {
                                      final appDir = await getApplicationDocumentsDirectory();
                                      final ext = tempAvatarPath!.split('.').last;
                                      final targetFile = File('${appDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext');
                                      final saved = await File(tempAvatarPath!).copy(targetFile.path);
                                      finalPath = saved.path;
                                    } catch (_) {
                                      finalPath = tempAvatarPath;
                                    }
                                  }

                                  await ProfileService.setUserName(newName);
                                  await ProfileService.setAvatarPath(finalPath);

                                  if (mounted) {
                                    setState(() {
                                      _userName = newName;
                                      _avatarPath = finalPath;
                                    });
                                  }
                                } catch (e) {
                                  debugPrint('Error saving profile: $e');
                                } finally {
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                  AppToast.success(s.profileSaved);
                                }
                              },
                        borderRadius: BorderRadius.circular(24),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryCtaGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x662F6BFF),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    s.saveChanges,
                                    style: AppTypography.bodyBold.copyWith(color: Colors.white, fontSize: 15),
                                  ),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. MANAGE WALLETS SHEET ---
  void _showManageWalletsSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final s = AppStrings.of(context);
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.manageWallets, style: AppTypography.titleMedium),
                        PressableScale(child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAddWalletDialog(context, provider);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  s.add,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.wallets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final wallet = provider.wallets[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(wallet.name, style: AppTypography.bodyBold),
                                      Text(_walletTypeLabel(wallet.type, s), style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatRupiah(wallet.currentBalance),
                                      style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    PressableScale(child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _showEditWalletDialog(context, provider, wallet);
                                      },
                                      child: Text(
                                        s.editBalance,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )),
                                    const SizedBox(height: 4),
                                    PressableScale(child: GestureDetector(
                                      onTap: () {
                                        if (provider.wallets.length <= 1) {
                                          AppToast.error(s.deleteWalletLastGuard);
                                          return;
                                        }
                                        _confirmDeleteWallet(context, provider,
                                            wallet, setSheetState, s);
                                      },
                                      child: Text(
                                        s.hapus,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Konfirmasi hapus dompet: guard dompet terakhir, dialog dulu,
  // FK RESTRICT (wallet berisi transaksi) → SnackBar jelas.
  Future<void> _confirmDeleteWallet(
    BuildContext context,
    FinanceProvider provider,
    WalletModel wallet,
    StateSetter setSheetState,
    AppStrings s,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteWalletConfirmTitle, style: AppTypography.titleMedium),
        content: Text(s.deleteWalletBody(wallet.name), style: AppTypography.bodyReg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.hapus, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await provider.deleteWallet(wallet.id);
      if (provider.selectedWalletId == wallet.id) {
        provider.selectWallet(null);
      }
      setSheetState(() {});
      if (context.mounted) {
        AppToast.success(s.deleteWalletSuccess(wallet.name));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          e.toString().toLowerCase().contains('foreign key')
              ? s.deleteWalletInUse
              : s.deleteWalletFailed(e.toString()),
        );
      }
    }
  }

  // Edit Wallet Dialog
  void _showEditWalletDialog(BuildContext context, FinanceProvider provider, WalletModel wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.currentBalance.toInt().toString());
    final s = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.editWallet, style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.walletName, style: AppTypography.caption),
            const SizedBox(height: 4),
            TextField(
              controller: nameController,
              style: AppTypography.bodyBold,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.currentBalanceLabel, style: AppTypography.caption),
            const SizedBox(height: 4),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: AppTypography.bodyBold,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              final rawBalance = balanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
              final newBalance = double.tryParse(rawBalance) ?? wallet.currentBalance;

              final updated = WalletModel(
                id: wallet.id,
                name: newName.isNotEmpty ? newName : wallet.name,
                type: wallet.type,
                initialBalance: wallet.initialBalance,
                currentBalance: newBalance,
                createdAt: wallet.createdAt,
              );

              await provider.updateWallet(updated);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppToast.success(s.walletUpdated(updated.name));
              }
            },
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Gemini API Key Dialog
  void _showApiKeyDialog(BuildContext context) {
    final scannerProvider = context.read<ScannerProvider>();
    final keyController = TextEditingController();
    final s = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Gemini API Key', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.apiKeyHelp,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyController,
              autofocus: true,
              obscureText: true,
              style: AppTypography.bodyBold,
              decoration: const InputDecoration(
                hintText: 'AIza...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final key = keyController.text.trim();
              if (key.isEmpty) return;
              await scannerProvider.setGeminiApiKey(key);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppToast.success(s.apiKeySavedMsg(key.length));
              }
            },
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Label tipe dompet untuk ditampilkan — nilai DB (types) tidak berubah.
  String _walletTypeLabel(String type, AppStrings s) {
    if (type == 'Tunai') return s.isEn ? 'Cash' : 'Tunai';
    if (type == 'Investasi') return s.isEn ? 'Investment' : 'Investasi';
    return type; // Bank, E-Wallet
  }

  // Add Wallet Dialog
  void _showAddWalletDialog(BuildContext context, FinanceProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'Bank';
    final types = ['Bank', 'E-Wallet', 'Tunai', 'Investasi'];
    final s = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.addWalletTitle, style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.walletNameField, style: AppTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: AppTypography.bodyBold,
                decoration: InputDecoration(
                  hintText: s.walletNameHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text(s.accountType, style: AppTypography.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: types.map((t) {
                  final isSelected = selectedType == t;
                  return ChoiceChip(
                    label: Text(_walletTypeLabel(t, s), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    onSelected: (val) => setDialogState(() => selectedType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(s.initialBalanceLabel, style: AppTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: AppTypography.bodyBold,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final rawBalance = balanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final balance = double.tryParse(rawBalance) ?? 0.0;

                final newWallet = WalletModel(
                  id: const Uuid().v4(),
                  name: name,
                  type: selectedType,
                  initialBalance: balance,
                  currentBalance: balance,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                );

                await provider.addWallet(newWallet);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppToast.success(s.walletAdded(name));
                }
              },
              child: Text(s.add, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. BACKUP & RESTORE BOTTOM SHEET ---
  void _showBackupRestoreSheet(BuildContext context, FinanceProvider provider) {
    final s = AppStrings.of(context);
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
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.backupSectionTitle, style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text(
                  s.backupSectionSubtitle,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 20),

                // Card 1: Create Backup
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.meshCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_upload_rounded, color: AppColors.meshCyan, size: 22),
                    ),
                    title: Text(s.createBackup, style: AppTypography.bodyBold),
                    subtitle: Text(s.createBackupSubtitle, style: AppTypography.caption),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final path = await provider.createBackup();
                        if (context.mounted) {
                          AppToast.success(s.backupSaved(path));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.error(s.backupFailed(e.toString()));
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Card 2: Restore Backup
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.restore_page_rounded, color: AppColors.secondary, size: 22),
                    ),
                    title: Text(s.restoreBackup, style: AppTypography.bodyBold),
                    subtitle: Text(s.restoreBackupSubtitle, style: AppTypography.caption),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRestoreFileListSheet(context, provider);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // File List Restore Sheet
  void _showRestoreFileListSheet(BuildContext context, FinanceProvider provider) async {
    final backups = await BackupManager.listAvailableBackups();

    if (!context.mounted) return;
    final s = AppStrings.of(context);

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
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.chooseBackupFile, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  s.backupsFound(backups.length),
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 16),

                if (backups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.folder_off_rounded, color: AppColors.textSecondary, size: 36),
                        const SizedBox(height: 10),
                        Text(s.noBackupYet, style: AppTypography.bodyBold),
                        const SizedBox(height: 4),
                        Text(
                          s.noBackupHint,
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...backups.map((file) {
                    final fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;
                    final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.description_rounded, color: AppColors.primaryLight, size: 22),
                        title: Text(fileName, style: AppTypography.bodyBold.copyWith(fontSize: 13)),
                        subtitle: Text('$sizeKb KB', style: AppTypography.caption),
                        trailing: Icon(Icons.restore_rounded, color: AppColors.secondary, size: 20),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await provider.restoreBackup(file);
                            AppToast.success(s.restoreDone);
                          } catch (e) {
                            AppToast.error(s.restoreFailed(e.toString()));
                          }
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 4. EXPORT FORMAT DIALOG (EXCEL / CSV TO DOWNLOADS) ---
  void _showExportDialog(BuildContext context, FinanceProvider provider) {
    String selectedFormat = 'excel';
    final s = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    const SizedBox(height: 16),
                    Text(s.exportTransactions, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      s.exportSubtitle,
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Option 1: Excel (.xlsx)
                    PressableScale(child: GestureDetector(
                      onTap: () => setSheetState(() => selectedFormat = 'excel'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedFormat == 'excel' ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedFormat == 'excel' ? AppColors.primary : AppColors.borderSubtle,
                            width: selectedFormat == 'excel' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.table_chart_rounded, color: AppColors.secondary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.excelFormat, style: AppTypography.bodyBold),
                                  Text(s.excelFormatDesc, style: AppTypography.caption),
                                ],
                              ),
                            ),
                            if (selectedFormat == 'excel')
                              Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 20),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 10),

                    // Option 2: CSV (.csv)
                    PressableScale(child: GestureDetector(
                      onTap: () => setSheetState(() => selectedFormat = 'csv'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedFormat == 'csv' ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedFormat == 'csv' ? AppColors.primary : AppColors.borderSubtle,
                            width: selectedFormat == 'csv' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.meshCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long_rounded, color: AppColors.meshCyan, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.csvFormat, style: AppTypography.bodyBold),
                                  Text(s.csvFormatDesc, style: AppTypography.caption),
                                ],
                              ),
                            ),
                            if (selectedFormat == 'csv')
                              Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 20),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 24),

                    // Export Button
                    PressableScale(child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          final path = await provider.exportTransactionsReport(format: selectedFormat);
                          if (context.mounted) {
                            AppToast.success(s.exportDone(path));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppToast.error(s.exportTransactionsFailed(e.toString()));
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryCtaGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            s.downloadToFolder,
                            style: AppTypography.bodyBold.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 5. MANAGE CUSTOM CATEGORIES SHEET ---
  void _showManageCategoriesSheet(BuildContext context, FinanceProvider provider) {
    String activeType = 'EXPENSE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categories = provider.categories.where((c) => c.type == activeType).toList();
            final s = AppStrings.of(context);

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.ledgerCategories, style: AppTypography.titleMedium),
                        PressableScale(child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAddCategoryDialog(context, provider, activeType);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  s.createCategory,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Type switcher
                    Row(
                      children: [
                        Expanded(
                          child: PressableScale(child: GestureDetector(
                            onTap: () => setSheetState(() => activeType = 'EXPENSE'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeType == 'EXPENSE' ? AppColors.error.withValues(alpha: 0.15) : AppColors.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: activeType == 'EXPENSE' ? AppColors.error : AppColors.borderSubtle,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  s.expense,
                                  style: AppTypography.bodyBold.copyWith(
                                    color: activeType == 'EXPENSE' ? AppColors.error : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PressableScale(child: GestureDetector(
                            onTap: () => setSheetState(() => activeType = 'INCOME'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeType == 'INCOME' ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: activeType == 'INCOME' ? AppColors.secondary : AppColors.borderSubtle,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  s.income,
                                  style: AppTypography.bodyBold.copyWith(
                                    color: activeType == 'INCOME' ? AppColors.secondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.category_rounded, size: 18, color: AppColors.primaryLight),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(cat.name, style: AppTypography.bodyBold.copyWith(fontSize: 14)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 18),
                                  onPressed: () async {
                                    await provider.deleteCategory(cat.id);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Budget ──

  /// Summary line for the settings row: how many categories are budgeted.
  String _budgetSubtitle(FinanceProvider provider) {
    final s = AppStrings.of(context);
    final expenseCats = provider.categories.where((c) => c.type == 'EXPENSE');
    final set = expenseCats.where((c) => provider.budgetFor(c.id) != null).length;
    if (set == 0) return s.noLimitYet;
    final now = DateTime.now();
    final totalLimit = expenseCats
        .map((c) => provider.budgetFor(c.id))
        .whereType<BudgetModel>()
        .fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final totalSpent = expenseCats
        .where((c) => provider.budgetFor(c.id) != null)
        .fold(0.0, (sum, c) => sum + provider.getCategorySpending(c.id, now.month, now.year));
    return s.budgetSummary(
      set,
      CurrencyFormatter.format(totalSpent),
      CurrencyFormatter.format(totalLimit),
    );
  }

  void _showBudgetSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final now = DateTime.now();
            final expenseCats =
                provider.categories.where((c) => c.type == 'EXPENSE').toList();
            final s = AppStrings.of(context);

            return SafeArea(
              child: Container(
                constraints:
                    BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.monthlyBudget, style: AppTypography.titleMedium),
                        Text(
                          // No 'id_ID' locale: intl needs
                          // initializeDateFormatting() for that and the app
                          // never calls it. Default locale keeps this
                          // consistent with the date formatting used elsewhere.
                          DateFormat('MMMM yyyy').format(now),
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.budgetHint,
                        style: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: expenseCats.isEmpty
                          ? Center(
                              child: Text(s.noExpenseCategories,
                                  style: AppTypography.caption),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: expenseCats.length,
                              itemBuilder: (context, index) {
                                final cat = expenseCats[index];
                                final budget = provider.budgetFor(cat.id);
                                final spent = provider.getCategorySpending(
                                    cat.id, now.month, now.year);

                                return PressableScale(child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    await _showBudgetLimitDialog(
                                        context, provider, cat, budget);
                                    setSheetState(() {});
                                  },
                                  child: budget == null
                                      ? _buildUnbudgetedRow(context, cat, spent)
                                      : BudgetProgressBar(
                                          categoryName: cat.name,
                                          spentAmount: spent,
                                          budgetLimit: budget.monthlyLimit,
                                        ),
                                ));
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Category with no limit yet — a progress bar would be meaningless, so show
  /// the spending so far plus a "set limit" affordance instead.
  Widget _buildUnbudgetedRow(BuildContext context, CategoryModel cat, double spent) {
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: AppTypography.labelLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  s.spentLabel(CurrencyFormatter.format(spent)),
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.setLimit,
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetLimitDialog(
    BuildContext context,
    FinanceProvider provider,
    CategoryModel category,
    BudgetModel? existing,
  ) async {
    final controller = TextEditingController(
      text: existing == null
          ? ''
          : existing.monthlyLimit.toInt().toString().replaceAllMapped(
              RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.'),
    );
    final s = AppStrings.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.limitTitle(category.name), style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.monthlyLimitField, style: AppTypography.caption),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: AppTypography.bodyBold,
              decoration: InputDecoration(
                hintText: s.limitHint,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                final now = DateTime.now();
                await provider.setBudget(BudgetModel(
                  id: existing.id,
                  categoryId: category.id,
                  monthlyLimit: 0,
                  month: now.month,
                  year: now.year,
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppToast.success(s.limitDeleted(category.name));
                }
              },
              child: Text(s.hapus,
                  style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final limit = double.tryParse(raw) ?? 0;
              if (limit <= 0) return;

              final now = DateTime.now();
              await provider.setBudget(BudgetModel(
                // Reuse the row id so repeated edits do not pile up duplicates.
                id: existing?.id ?? const Uuid().v4(),
                categoryId: category.id,
                monthlyLimit: limit,
                month: now.month,
                year: now.year,
              ));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppToast.success(
                    s.limitSaved(category.name, CurrencyFormatter.format(limit)));
              }
            },
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Add Category Dialog
  void _showAddCategoryDialog(BuildContext context, FinanceProvider provider, String defaultType) {
    final nameController = TextEditingController();
    String categoryType = defaultType;
    final s = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.createCategoryTitle, style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.categoryName, style: AppTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: AppTypography.bodyBold,
                decoration: InputDecoration(
                  hintText: s.categoryNameHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text(s.transactionType, style: AppTypography.caption),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(s.expense, style: const TextStyle(fontSize: 12)),
                    selected: categoryType == 'EXPENSE',
                    selectedColor: AppColors.error,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    onSelected: (val) => setDialogState(() => categoryType = 'EXPENSE'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(s.income, style: const TextStyle(fontSize: 12)),
                    selected: categoryType == 'INCOME',
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    onSelected: (val) => setDialogState(() => categoryType = 'INCOME'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newCat = CategoryModel(
                  id: const Uuid().v4(),
                  name: name,
                  type: categoryType,
                  icon: 'category',
                  color: '#2F6BFF',
                );

                await provider.addCategory(newCat);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppToast.success(s.categoryAdded(name));
                }
              },
              child: Text(s.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.borderSubtle, indent: 56, endIndent: 16);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return PressableScale(child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Squircle Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    ));
  }
}
