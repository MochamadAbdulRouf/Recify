import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../providers/finance_provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.read<FinanceProvider>();
    final isExpense = transaction.type == 'EXPENSE';
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.transactionDate);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        title: Text('Detail Transaksi', style: AppTypography.headlineMd),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmDelete(context, financeProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Photo Preview (if exists)
            if (transaction.receiptImagePath != null && transaction.receiptImagePath!.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(transaction.receiptImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 40),
                    ),
                  ),
                ),
              ),

            // Hero Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    transaction.merchantName ?? 'Transaksi',
                    style: AppTypography.titleSm,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (isExpense ? '-' : '+') + CurrencyFormatter.formatRupiah(transaction.amount),
                    style: AppTypography.displayLg.copyWith(
                      color: isExpense ? AppColors.error : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatFull(date),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Transaction Metadata
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildMetaRow('Kategori', transaction.category?.name ?? 'Umum', Icons.category_outlined),
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  _buildMetaRow('Dompet / Akun', transaction.wallet?.name ?? 'Utama', Icons.account_balance_wallet_outlined),
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  _buildMetaRow('Tipe', isExpense ? 'Pengeluaran' : 'Pemasukan', isExpense ? Icons.arrow_upward : Icons.arrow_downward),
                  if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    _buildMetaRow('Catatan', transaction.notes!, Icons.note_outlined),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Itemized Breakdown (if receipt had items)
            if (transaction.items.isNotEmpty) ...[
              Text(
                'Rincian Belanja (${transaction.items.length} Item)',
                style: AppTypography.titleSm,
              ),
              const SizedBox(height: 10),
              ...transaction.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName, style: AppTypography.bodyBold),
                          Text(
                            '${item.quantity.toInt()} x ${CurrencyFormatter.formatRupiah(item.unitPrice)}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(item.totalPrice),
                        style: AppTypography.bodyBold,
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodyReg),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyBold,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurfaceElevated,
          title: const Text('Hapus Transaksi?'),
          content: const Text('Saldo dompet akan disesuaikan kembali secara otomatis.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.deleteTransaction(transaction);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
