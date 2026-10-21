import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/currencies.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/exchange_rate_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/exchange_rate_provider.dart';

/// Pemilih mata uang untuk form nominal.
///
/// Trigger menampilkan bendera + simbol + kode; tap membuka bottom sheet
/// berisi 15 mata uang dalam halaman-halaman (5 per halaman) yang bisa
/// digeser, dengan indikator dots. Self-contained: membaca
/// [ExchangeRateProvider] untuk caption umur kurs ("kurs per 16 Okt,
/// 2 hari lalu") saat status [RateStatus.stale]. Guard konversi (kurs
/// null → blokir save) tetap tanggung jawab pemanggil, bukan widget ini.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.textColor,
    this.fontSize = 32,
  });

  /// Kode mata uang terpilih, mis. 'IDR', 'USD'.
  final String value;

  final ValueChanged<String> onChanged;

  /// Warna teks simbol/kode; null = ikut tema.
  final Color? textColor;

  /// Ukuran teks simbol/kode di trigger (form nominal besar).
  final double fontSize;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CurrencyPickerSheet(
        selected: value,
        onSelected: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExchangeRateProvider>();
    final showStaleCaption = provider.status == RateStatus.stale;
    final option = currencyByCode(value);

    final style = AppTypography.headlineMd.copyWith(
      fontSize: fontSize * 0.6,
      color: textColor,
      fontWeight: FontWeight.w700,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => _openSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.flag,
                  style: TextStyle(fontSize: fontSize * 0.6),
                ),
                const SizedBox(width: 4),
                Text('${option.symbol} ${option.code}', style: style),
                Icon(
                  Icons.expand_more_rounded,
                  size: fontSize * 0.5,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
        if (showStaleCaption)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              provider.ageLabel,
              style: AppTypography.caption.copyWith(
                color: textColor?.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet pemilih mata uang: halaman berisi 5 baris, digeser dengan
/// PageView, indikator dots di bawah. Terbuka langsung di halaman yang
/// memuat mata uang terpilih.
class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  static const int _perPage = 5;
  static const double _rowHeight = 52;

  late final PageController _pageController;
  int _page = 0;

  int get _pageCount => (kSupportedCurrencies.length / _perPage).ceil();

  @override
  void initState() {
    super.initState();
    final idx =
        kSupportedCurrencies.indexWhere((c) => c.code == widget.selected);
    _page = idx < 0 ? 0 : idx ~/ _perPage;
    _pageController = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _pick(String code) {
    Navigator.pop(context);
    if (code != widget.selected) widget.onSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.currencyLabel, style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: _perPage * _rowHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * _perPage;
                  final end =
                      (start + _perPage).clamp(0, kSupportedCurrencies.length);
                  return Column(
                    children: [
                      for (final c
                          in kSupportedCurrencies.sublist(start, end))
                        _CurrencyTile(
                          option: c,
                          selected: c.code == widget.selected,
                          onTap: () => _pick(c.code),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primary
                          : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CurrencyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Text(option.code, style: AppTypography.bodyBold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${option.symbol} - ${option.name}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
