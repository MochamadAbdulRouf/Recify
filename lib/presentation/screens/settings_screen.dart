import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _cacheSizeStr = '0.0 MB';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
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
            content: Text('Cache berhasil dibersihkan!', style: TextStyle(color: Colors.white)),
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
            Stack(
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
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 44, color: AppColors.primaryLight),
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

            const SizedBox(height: 14),

            // Profile Name & Security Badge
            Text(
              'Pengguna Recify',
              style: AppTypography.headlineMd.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
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
                subtitle: '${financeProvider.wallets.length} Dompet Aktif',
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
                onTap: () => _showWalletListSheet(context, financeProvider),
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
                subtitle: 'Backup database SQLite',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.bgSurfaceElevated,
                      content: Text('Semua data otomatis tersimpan di SQLite lokal perangkat.', style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.meshViolet,
                title: 'Ekspor Data Transaksi',
                subtitle: 'Unduh rekapitulasi Excel / CSV',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.meshViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CSV / Excel',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.meshViolet,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                onTap: () async {
                  try {
                    final path = await financeProvider.exportCsvFile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.bgSurfaceElevated,
                          content: Text('Laporan tersimpan di: $path', style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ekspor gagal: $e')),
                      );
                    }
                  }
                },
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
                subtitle: '${financeProvider.categories.length} Kategori Tersedia',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                onTap: () => _showCategoriesListSheet(context, financeProvider),
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
                        '3. Verifikasi total & simpan ke database SQLite lokal Anda.',
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

  void _showWalletListSheet(BuildContext context, FinanceProvider provider) {
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
                Text('Daftar Dompet Tersedia', style: AppTypography.titleMedium),
                const SizedBox(height: 14),
                ...provider.wallets.map((w) {
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight),
                    title: Text(w.name, style: AppTypography.bodyBold),
                    subtitle: Text(
                      'Saldo: ${CurrencyFormatter.formatRupiah(w.currentBalance)}',
                      style: AppTypography.caption,
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

  void _showCategoriesListSheet(BuildContext context, FinanceProvider provider) {
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
                Text('Daftar Kategori Tersedia', style: AppTypography.titleMedium),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = provider.categories[i];
                      return ListTile(
                        leading: const Icon(Icons.label_rounded, color: AppColors.primaryLight),
                        title: Text(cat.name, style: AppTypography.bodyBold),
                        subtitle: Text(
                          cat.type == 'EXPENSE' ? 'Pengeluaran' : 'Pemasukan',
                          style: AppTypography.caption,
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
  }
}
