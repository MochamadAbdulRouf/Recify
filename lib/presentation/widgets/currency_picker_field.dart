import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/currencies.dart';
import '../../core/services/exchange_rate_service.dart';
import '../../core/theme/app_typography.dart';
import '../providers/exchange_rate_provider.dart';

/// Dropdown pemilih mata uang untuk form nominal.
///
/// Self-contained: membaca [ExchangeRateProvider] dari context dan
/// menampilkan caption umur kurs ("kurs per 16 Okt, 2 hari lalu") di
/// bawah dropdown saat status [RateStatus.stale]. Guard konversi (kurs
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

  /// Ukuran teks simbol/kode di tombol dropdown (form nominal besar).
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExchangeRateProvider>();
    final showStaleCaption = provider.status == RateStatus.stale;

    final style = AppTypography.headlineMd.copyWith(
      fontSize: fontSize,
      color: textColor,
      fontWeight: FontWeight.w700,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: kSupportedCurrencies.any((c) => c.code == value)
                ? value
                : kBaseCurrency,
            isDense: true,
            icon: Icon(
              Icons.expand_more_rounded,
              size: fontSize * 0.5,
              color: textColor,
            ),
            items: [
              for (final c in kSupportedCurrencies)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(
                    '${c.symbol} ${c.code}',
                    style: style.copyWith(fontSize: fontSize * 0.6),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null && v != value) onChanged(v);
            },
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
