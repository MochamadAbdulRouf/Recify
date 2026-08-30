import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../providers/finance_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: StickyFrostedAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pengaturan & Akun', style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              'Preferensi Aplikasi & Data Lokal',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Local Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Icon(Icons.person_rounded, size: 26, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pengguna Recify', style: AppTypography.titleSm),
                        const SizedBox(height: 2),
                        Text(
                          'Penyimpanan Offline Lokal • Privasi Penuh',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Wallets & Accounts Section
            Text('Daftar Dompet & Akun', style: AppTypography.titleSm),
            const SizedBox(height: 12),
            ...financeProvider.wallets.map((wallet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.name, style: AppTypography.bodyBold),
                            Text(wallet.type, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(wallet.currentBalance),
                        style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // 3. Security & Data Storage Section
            Text('Privasi & Keamanan Data', style: AppTypography.titleSm),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'Keamanan Data 100% Offline',
              subtitle: 'Semua struk dan transaksi disimpan di SQLite HP Anda',
              trailing: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.cloud_off_rounded,
              title: 'Zero Cloud Storage',
              subtitle: 'Tidak ada data keuangan yang dikirim ke server pihak ketiga',
              trailing: const Icon(Icons.verified_user_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.file_download_outlined,
              title: 'Ekspor Data ke CSV',
              subtitle: 'Unduh seluruh riwayat pembukuan dalam format spreadsheet',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              onTap: () async {
                try {
                  final path = await financeProvider.exportCsvFile();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.bgSurfaceElevated,
                        content: Text('Data berhasil diekspor ke: $path', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengekspor: $e')),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 24),

            // 4. App Info Section
            Text('Tentang Aplikasi', style: AppTypography.titleSm),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'Recify Versi 1.0.0',
              subtitle: 'Smart Receipt Scanner & Local Expense Tracker',
            ),

            const SizedBox(height: 100), // Space for Floating Island Navbar
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
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
                  Text(title, style: AppTypography.bodyBold.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
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
