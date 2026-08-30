import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/transaction_model.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../components/transaction_list_item.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['Semua', 'Pengeluaran', 'Pemasukan'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();

    // Filter transactions
    final filtered = financeProvider.transactions.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          (t.merchantName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.category?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.notes ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Pengeluaran') return t.type == 'EXPENSE';
      if (_selectedFilter == 'Pemasukan') return t.type == 'INCOME';
      return true;
    }).toList();

    // Group transactions by date string
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      final now = DateTime.now();
      String header;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        header = 'HARI INI';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.subtract(const Duration(days: 1)).day) {
        header = 'KEMARIN';
      } else {
        header = DateFormat('d MMM yyyy').format(date).toUpperCase();
      }

      grouped.putIfAbsent(header, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      // Fixed / Sticky Frosted Header with Embedded Search & Filter
      appBar: StickyFrostedAppBar(
        height: 60,
        bottomHeight: 110,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Riwayat Transaksi', style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              '${filtered.length} transaksi tercatat',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ekspor CSV',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.file_download_outlined, color: AppColors.primaryLight, size: 18),
            ),
            onPressed: () async {
              try {
                final path = await financeProvider.exportCsvFile();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal ekspor: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Search Input
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Cari transaksi, merchant, catatan...',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 16),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Filter Chips
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final f = _filters[i];
                    final isSelected = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          f,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('Tidak ada transaksi ditemukan', style: AppTypography.bodyBold),
                  const SizedBox(height: 4),
                  Text('Coba ubah kata kunci pencarian atau filter', style: AppTypography.caption),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: grouped.length + 1,
              itemBuilder: (ctx, index) {
                if (index == grouped.length) {
                  return const SizedBox(height: 100); // Space for Floating Island Navbar
                }

                final header = grouped.keys.elementAt(index);
                final items = grouped[header]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                      child: Text(
                        header,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    ...items.map((tx) {
                      return TransactionListItem(
                        transaction: tx,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(transaction: tx),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
