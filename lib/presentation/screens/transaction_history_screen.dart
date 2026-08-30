import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/transaction_model.dart';
import '../components/transaction_list_item.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Expense', 'Income', 'Transfers'];

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

      if (_selectedFilter == 'Expense') return t.type == 'EXPENSE';
      if (_selectedFilter == 'Income') return t.type == 'INCOME';
      if (_selectedFilter == 'Transfers') return t.type == 'TRANSFER';
      return true;
    }).toList();

    // Group transactions by date string
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
      final now = DateTime.now();
      String header;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        header = 'TODAY';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.subtract(const Duration(days: 1)).day) {
        header = 'YESTERDAY';
      } else {
        header = DateFormat('MMM d, yyyy').format(date).toUpperCase();
      }

      grouped.putIfAbsent(header, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        title: Text('Wallet & History', style: AppTypography.headlineMd),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () async {
              try {
                final path = await financeProvider.exportCsvFile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Laporan berhasil diekspor ke: $path')),
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
      ),
      body: Column(
        children: [
          // 1. Search Bar & Horizontal Filter Chips matching Stitch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Column(
              children: [
                // Search Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.outline, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.bodyReg,
                          decoration: InputDecoration(
                            hintText: 'Search transactions, merchants...',
                            hintStyle: AppTypography.bodyReg.copyWith(color: AppColors.outline),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.outline),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: AppTypography.labelMd.copyWith(
                                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Grouped Transaction List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppColors.outline.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada transaksi yang cocok',
                          style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: grouped.keys.length + 1, // +1 for bottom padding
                    itemBuilder: (context, index) {
                      if (index == grouped.keys.length) {
                        return const SizedBox(height: 90); // Floating navbar space
                      }

                      final header = grouped.keys.elementAt(index);
                      final items = grouped[header]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8),
                            child: Text(
                              header,
                              style: AppTypography.labelMd.copyWith(
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
          ),
        ],
      ),
    );
  }
}
