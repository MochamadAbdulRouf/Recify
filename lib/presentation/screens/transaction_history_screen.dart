import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transaction_filter.dart';
import '../../data/models/transaction_model.dart';
import '../components/app_toast.dart';
import '../components/sticky_frosted_app_bar.dart';
import '../components/export_format_dialog.dart';
import '../components/transaction_list_item.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // Filter stored as type key so locale switch never breaks matching
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filters = ['ALL', 'EXPENSE', 'INCOME'];

  String _filterLabel(AppStrings s, String key) {
    if (key == 'EXPENSE') return s.filterExpense;
    if (key == 'INCOME') return s.filterIncome;
    return s.filterAll;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);

    // Filter transactions (shared matcher with the global search screen)
    final filtered = TransactionFilter.apply(
      financeProvider.transactions,
      query: _searchQuery,
      type: _selectedFilter,
    );

    // Group transactions by date string
    final Map<String, List<TransactionModel>> grouped =
        TransactionFilter.groupByDay(filtered, s);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      // Fixed / Sticky Frosted Header with Embedded Search & Filter
      appBar: StickyFrostedAppBar(
        height: 64,
        bottomHeight: 104,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.historyTitle,
                style: AppTypography.headlineMd.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              s.historyCount(filtered.length),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
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
              child: Icon(Icons.file_download_outlined,
                  color: AppColors.primaryLight, size: 18),
            ),
            onPressed: () async {
              final format = await ExportFormatDialog.show(context);
              if (format == null || !context.mounted) return; // batal
              try {
                final path = await financeProvider.exportTransactionsReport(
                  format: format == ExportFormat.excel ? 'excel' : 'csv',
                );
                if (context.mounted) {
                  AppToast.success(AppStrings.of(context).exportDone(path));
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(
                      AppStrings.of(context).exportTransactionsFailed(e.toString()));
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
                    Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: s.searchHint,
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
                        child: Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 16),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          _filterLabel(s, f),
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
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
                  Icon(Icons.search_off_rounded,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(s.emptyHistoryTitle, style: AppTypography.bodyBold),
                  const SizedBox(height: 4),
                  Text(s.emptyHistoryHint, style: AppTypography.caption),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: grouped.length + 1,
              itemBuilder: (ctx, index) {
                if (index == grouped.length) {
                  return const SizedBox(
                      height: 132); // Space for Floating Island + FAB
                }

                final header = grouped.keys.elementAt(index);
                final items = grouped[header]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 14, bottom: 8, left: 4),
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
                              builder: (_) =>
                                  TransactionDetailScreen(transaction: tx),
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
