import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/finance_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        title: Text('Pengaturan & Akun', style: AppTypography.headlineMd),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

            // 2. Data & Export Section
            Text('Manajemen Data & Laporan', style: AppTypography.titleSm),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.secondary),
                    title: Text('Ekspor Transaksi ke CSV', style: AppTypography.bodyBold),
                    subtitle: Text('Simpan riwayat transaksi ke file Excel/CSV lokal', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
                            SnackBar(content: Text('Gagal ekspor: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.primaryLight),
                    title: Text('Keamanan Data Offline', style: AppTypography.bodyBold),
                    subtitle: Text('Database SQLite dan foto struk tersimpan di HP Anda', style: AppTypography.caption),
                    trailing: const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Wallets Section
            Text('Dompet & Saldo (${financeProvider.wallets.length})', style: AppTypography.titleSm),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: financeProvider.wallets.map((w) {
                  return ListTile(
                    leading: Icon(
                      w.type == 'CASH'
                          ? Icons.payments_outlined
                          : (w.type == 'BANK' ? Icons.account_balance_outlined : Icons.phone_android_outlined),
                      color: AppColors.meshCyan,
                    ),
                    title: Text(w.name, style: AppTypography.bodyBold),
                    subtitle: Text(
                      'Saldo: ${CurrencyFormatter.formatRupiah(w.currentBalance)}',
                      style: AppTypography.caption,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Categories Section
            Text('Kategori Transaksi (${financeProvider.categories.length})', style: AppTypography.titleSm),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: financeProvider.categories.take(6).map((cat) {
                  final isExpense = cat.type == 'EXPENSE';
                  return ListTile(
                    leading: Icon(
                      Icons.label_outline_rounded,
                      color: isExpense ? AppColors.error : AppColors.secondary,
                    ),
                    title: Text(cat.name, style: AppTypography.bodyBold),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExpense ? AppColors.statusNegativeBg : AppColors.statusPositiveBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isExpense ? 'Pengeluaran' : 'Pemasukan',
                        style: AppTypography.caption.copyWith(
                          color: isExpense ? AppColors.error : AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 100), // Navbar space
          ],
        ),
      ),
    );
  }
}
