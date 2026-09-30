import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transaction_filter.dart';
import '../../data/models/transaction_model.dart';
import '../components/glass_panel.dart';
import '../components/transaction_list_item.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

/// Full-screen search over the local transaction history: merchant, note,
/// category name and nominal, plus type / category / wallet chips.
///
/// All filtering happens on the already-loaded [FinanceProvider.transactions]
/// list — no extra query per keystroke. The dataset is one user's own records,
/// so an in-memory scan is faster than a DB round-trip.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  String _query = '';
  String _type = 'ALL';
  String? _categoryId;
  String? _walletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.trim().length < 2) return;
    context.read<FinanceProvider>().addRecentSearch(value);
  }

  void _useQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
    _submit(q);
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final s = AppStrings.of(context);

    final results = TransactionFilter.apply(
      finance.transactions,
      query: _query,
      type: _type,
      categoryId: _categoryId,
      walletId: _walletId,
    );
    final grouped = TransactionFilter.groupByDay(results, s);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: GlassPanel(
                          radius: 16,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: AppColors.textSecondary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (v) => setState(() => _query = v),
                                  onSubmitted: _submit,
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontSize: 13),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: s.searchHint,
                                    hintStyle: AppTypography.caption,
                                  ),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final t in const ['ALL', 'EXPENSE', 'INCOME'])
                        _Chip(
                          label: t == 'ALL'
                              ? s.filterAll
                              : (t == 'EXPENSE' ? s.expense : s.income),
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ),
                      for (final c in finance.categories)
                        _Chip(
                          label: c.name,
                          selected: _categoryId == c.id,
                          onTap: () => setState(() =>
                              _categoryId = _categoryId == c.id ? null : c.id),
                        ),
                      for (final w in finance.wallets)
                        _Chip(
                          label: w.name,
                          selected: _walletId == w.id,
                          onTap: () => setState(() =>
                              _walletId = _walletId == w.id ? null : w.id),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Expanded(
                  child: _query.trim().isEmpty
                      ? _RecentSearches(
                          s: s,
                          queries: finance.recentSearches,
                          onPick: _useQuery,
                          onClear: finance.clearRecentSearches,
                        )
                      : results.isEmpty
                          ? _NoResult(s: s)
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    s.resultCount(results.length),
                                    style: AppTypography.caption,
                                  ),
                                ),
                                for (final entry in grouped.entries) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                    child: Text(
                                      entry.key,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  for (final TransactionModel tx in entry.value)
                                    TransactionListItem(
                                      transaction: tx,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TransactionDetailScreen(
                                                  transaction: tx),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.s,
    required this.queries,
    required this.onPick,
    required this.onClear,
  });

  final AppStrings s;
  final List<String> queries;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(s.searchHint,
              textAlign: TextAlign.center, style: AppTypography.caption),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.searchRecent, style: AppTypography.bodyBold),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  s.searchClearRecent,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in queries)
              _Chip(label: q, selected: false, onTap: () => onPick(q)),
          ],
        ),
      ],
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                color: AppColors.textSecondary, size: 30),
            const SizedBox(height: 14),
            Text(s.searchEmptyTitle,
                textAlign: TextAlign.center, style: AppTypography.bodyBold),
            const SizedBox(height: 6),
            Text(s.searchEmptyHint,
                textAlign: TextAlign.center, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
