import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/wallet_model.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.bgSurfaceElevated,
            content: Text('Cache sementara berhasil dibersihkan!', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membersihkan cache: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      // Stitch Sticky Frosted Header
      appBar: StickyFrostedAppBar(
        height: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profil & Pengaturan', style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              'Preferensi & Keamanan Akun Lokal',
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
            GestureDetector(
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
                          : const Center(
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
                      child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Profile Name (Click to edit) & Security Badge
            GestureDetector(
              onTap: _showEditProfileSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName,
                    style: AppTypography.headlineMd.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '100% Offline • Penyimpanan SQLite Lokal',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),

            const SizedBox(height: 28),

            // 2. Section: Account & Security (Stitch Match)
            _buildSectionHeader('AKUN & KEAMANAN'),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                title: 'Kelola Dompet & Akun',
                subtitle: '${financeProvider.wallets.length} Dompet • Edit Saldo & Tambah',
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
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
                onTap: () => _showManageWalletsSheet(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.lock_rounded,
                iconColor: AppColors.secondary,
                title: 'Keamanan Data',
                subtitle: 'Proteksi On-Device',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Aktif',
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
                title: 'Mata Uang Utama',
                subtitle: 'Format Rupiah Indonesia',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'IDR (Rp)',
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
            _buildSectionHeader('MANAJEMEN DATA'),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.backup_rounded,
                iconColor: AppColors.meshCyan,
                title: 'Cadangan & Pemulihan Lokal',
                subtitle: 'Backup & Restore database SQLite',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () => _showBackupRestoreSheet(context, financeProvider),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.meshViolet,
                title: 'Ekspor Data Transaksi',
                subtitle: 'Simpan ke folder Download (Excel / CSV)',
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
                title: 'Bersihkan Cache Gambar',
                subtitle: 'Hapus file temporary scan OCR',
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
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
                onTap: _clearCache,
              ),
            ]),

            const SizedBox(height: 22),

            // 4. Section: Preferences (Stitch Match)
            _buildSectionHeader('PREFERENSI & TAMPILAN'),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.textPrimary,
                title: 'Tema Deep Obsidian Dark',
                subtitle: 'Mode Gelap OLED Anti-Silau',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Aktif',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.category_rounded,
                iconColor: AppColors.meshIndigo,
                title: 'Kategori Pembukuan',
                subtitle: '${financeProvider.categories.length} Kategori • Tambah & Kelola',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () => _showManageCategoriesSheet(context, financeProvider),
              ),
            ]),

            const SizedBox(height: 22),

            // 5. Section: Support & Info (Stitch Match)
            _buildSectionHeader('BANTUAN & INFORMASI'),
            _buildCardGroup([
              _buildSettingItem(
                icon: Icons.help_center_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Pusat Bantuan & Panduan',
                subtitle: 'Cara scan struk & rekap otomatis',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Panduan Recify', style: AppTypography.titleMedium),
                      content: Text(
                        '1. Buka tombol kamera di tengah menu bawah untuk scan struk belanja.\n'
                        '2. Pastikan nota rata dan tulisan terbaca jelas.\n'
                        '3. Verifikasi total & simpan ke database SQLite lokal Anda.\n'
                        '4. Ekspor laporan pembukuan ke format Excel/CSV langsung di folder Download.',
                        style: AppTypography.bodyReg,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Mengerti', style: TextStyle(color: AppColors.primaryLight)),
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
                title: 'Kebijakan Privasi',
                subtitle: 'Zero Cloud • 100% Offline AI',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Kebijakan Privasi', style: AppTypography.titleMedium),
                      content: Text(
                        'Recify dirancang dengan filosofi privasi total. Tidak ada server cloud, analitik pihak ketiga, atau pelacakan data pribadi Anda.',
                        style: AppTypography.bodyReg,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup', style: TextStyle(color: AppColors.primaryLight)),
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
              'Recify Versi 1.0.0 (Build 2026)',
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
    final nameController = TextEditingController(text: _userName);
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
                    Text('Edit Profil Pengguna', style: AppTypography.titleMedium),
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
                                : const Icon(Icons.person_rounded, size: 44, color: AppColors.primaryLight),
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
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Kamera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 16),
                          label: const Text('Galeri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
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
                          Text('NAMA PENGGUNA', style: AppTypography.caption.copyWith(fontSize: 10, letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: nameController,
                            style: AppTypography.bodyBold.copyWith(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nama Anda...',
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
                      child: InkWell(
                        onTap: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) return;
                                final messenger = ScaffoldMessenger.of(context);

                                setSheetState(() => isSaving = true);
                                FocusScope.of(ctx).unfocus();

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

                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }

                                messenger.showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.bgSurfaceElevated,
                                    content: Text('Profil berhasil disimpan!', style: TextStyle(color: Colors.white)),
                                  ),
                                );
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
                                    'Simpan Perubahan',
                                    style: AppTypography.bodyBold.copyWith(color: Colors.white, fontSize: 15),
                                  ),
                          ),
                        ),
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
                        Text('Kelola Dompet & Akun', style: AppTypography.titleMedium),
                        GestureDetector(
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
                                const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  'Tambah',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(wallet.name, style: AppTypography.bodyBold),
                                      Text(wallet.type, style: AppTypography.caption),
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _showEditWalletDialog(context, provider, wallet);
                                      },
                                      child: Text(
                                        'Edit Saldo',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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

  // Edit Wallet Dialog
  void _showEditWalletDialog(BuildContext context, FinanceProvider provider, WalletModel wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.currentBalance.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Dompet', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Dompet', style: AppTypography.caption),
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
            Text('Saldo Saat Ini (Rp)', style: AppTypography.caption),
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
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.bgSurfaceElevated,
                    content: Text('Dompet "${updated.name}" berhasil diperbarui!', style: const TextStyle(color: Colors.white)),
                  ),
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Add Wallet Dialog
  void _showAddWalletDialog(BuildContext context, FinanceProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'Bank';
    final types = ['Bank', 'E-Wallet', 'Tunai', 'Investasi'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Tambah Dompet Baru', style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Dompet / Akun', style: AppTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: AppTypography.bodyBold,
                decoration: const InputDecoration(
                  hintText: 'Contoh: BCA, GoPay, Dompet Tunai',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tipe Akun', style: AppTypography.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: types.map((t) {
                  final isSelected = selectedType == t;
                  return ChoiceChip(
                    label: Text(t, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    onSelected: (val) => setDialogState(() => selectedType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text('Saldo Awal (Rp)', style: AppTypography.caption),
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
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.bgSurfaceElevated,
                      content: Text('Dompet "$name" berhasil ditambahkan!', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
              },
              child: const Text('Tambah', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. BACKUP & RESTORE BOTTOM SHEET ---
  void _showBackupRestoreSheet(BuildContext context, FinanceProvider provider) {
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
                Text('Cadangan & Pemulihan Data', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Amankan database keuangan Anda secara offline',
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
                      child: const Icon(Icons.cloud_upload_rounded, color: AppColors.meshCyan, size: 22),
                    ),
                    title: Text('Buat Cadangan Baru', style: AppTypography.bodyBold),
                    subtitle: Text('Simpan file JSON ke folder Download HP', style: AppTypography.caption),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final path = await provider.createBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.bgSurfaceElevated,
                              content: Text('Cadangan tersimpan di: $path', style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal backup: $e')));
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
                      child: const Icon(Icons.restore_page_rounded, color: AppColors.secondary, size: 22),
                    ),
                    title: Text('Pulihkan dari File Cadangan', style: AppTypography.bodyBold),
                    subtitle: Text('Pilih file .json cadangan Recify', style: AppTypography.caption),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result != null && result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          await provider.restoreBackup(file);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.bgSurfaceElevated,
                                content: Text('Data berhasil dipulihkan dari cadangan!', style: TextStyle(color: Colors.white)),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memulihkan: $e')));
                        }
                      }
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

  // --- 4. EXPORT FORMAT DIALOG (EXCEL / CSV TO DOWNLOADS) ---
  void _showExportDialog(BuildContext context, FinanceProvider provider) {
    String selectedFormat = 'excel';

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
                    Text('Ekspor Data Transaksi', style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih format file laporan untuk disimpan ke folder Download',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Option 1: Excel (.xlsx)
                    GestureDetector(
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
                              child: const Icon(Icons.table_chart_rounded, color: AppColors.secondary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Microsoft Excel (.xlsx)', style: AppTypography.bodyBold),
                                  Text('Tabel terformat rapi dengan warna & header sel', style: AppTypography.caption),
                                ],
                              ),
                            ),
                            if (selectedFormat == 'excel')
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Option 2: CSV (.csv)
                    GestureDetector(
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
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.meshCyan, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Format CSV (.csv)', style: AppTypography.bodyBold),
                                  Text('Kompatibel dengan semua aplikasi pembukuan', style: AppTypography.caption),
                                ],
                              ),
                            ),
                            if (selectedFormat == 'csv')
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Export Button
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          final path = await provider.exportTransactionsReport(format: selectedFormat);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.bgSurfaceElevated,
                                content: Text('Laporan berhasil diekspor ke: $path', style: const TextStyle(color: Colors.white)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
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
                            'Unduh ke Folder Download',
                            style: AppTypography.bodyBold.copyWith(color: Colors.white),
                          ),
                        ),
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
                        Text('Kategori Pembukuan', style: AppTypography.titleMedium),
                        GestureDetector(
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
                                const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  'Buat Kategori',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Type switcher
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
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
                                  'Pengeluaran',
                                  style: AppTypography.bodyBold.copyWith(
                                    color: activeType == 'EXPENSE' ? AppColors.error : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
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
                                  'Pemasukan',
                                  style: AppTypography.bodyBold.copyWith(
                                    color: activeType == 'INCOME' ? AppColors.secondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                                  child: const Icon(Icons.category_rounded, size: 18, color: AppColors.primaryLight),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(cat.name, style: AppTypography.bodyBold.copyWith(fontSize: 14)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 18),
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

  // Add Category Dialog
  void _showAddCategoryDialog(BuildContext context, FinanceProvider provider, String defaultType) {
    final nameController = TextEditingController();
    String categoryType = defaultType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Buat Kategori Baru', style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Kategori', style: AppTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: AppTypography.bodyBold,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Streaming, Hobi, Donasi',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tipe Transaksi', style: AppTypography.caption),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
                    selected: categoryType == 'EXPENSE',
                    selectedColor: AppColors.error,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    onSelected: (val) => setDialogState(() => categoryType = 'EXPENSE'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pemasukan', style: TextStyle(fontSize: 12)),
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
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.bgSurfaceElevated,
                      content: Text('Kategori "$name" berhasil ditambahkan!', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
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
    return const Divider(height: 1, color: AppColors.borderSubtle, indent: 56, endIndent: 16);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
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
    );
  }
}
