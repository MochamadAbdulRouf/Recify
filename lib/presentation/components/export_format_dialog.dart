import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'pressable.dart';

/// Format file yang dipilih user di dialog ekspor.
enum ExportFormat { excel, csv }

/// Dialog pilih format ekspor (Excel/CSV), dipakai ulang oleh
/// Home, History, dan Stats. Tanpa gradient/animasi — satu warna
/// permukaan + ikon + radio, mengikuti token tema (light/dark aman).
///
/// Kembalikan [ExportFormat], atau null kalau user batal.
class ExportFormatDialog extends StatefulWidget {
  const ExportFormatDialog({super.key});

  /// Tampilkan dialog; hasil null = batal.
  static Future<ExportFormat?> show(BuildContext context) {
    return showDialog<ExportFormat>(
      context: context,
      builder: (_) => const ExportFormatDialog(),
    );
  }

  @override
  State<ExportFormatDialog> createState() => _ExportFormatDialogState();
}

class _ExportFormatDialogState extends State<ExportFormatDialog> {
  ExportFormat _selected = ExportFormat.excel;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.exportFormatTitle, style: AppTypography.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExportFormatOption(
            icon: Icons.table_chart_outlined,
            label: s.exportFormatExcel,
            selected: _selected == ExportFormat.excel,
            onTap: () => setState(() => _selected = ExportFormat.excel),
          ),
          const SizedBox(height: 8),
          ExportFormatOption(
            icon: Icons.description_outlined,
            label: s.exportFormatCsv,
            selected: _selected == ExportFormat.csv,
            onTap: () => setState(() => _selected = ExportFormat.csv),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(s.downloadAction),
        ),
      ],
    );
  }
}

/// Satu baris opsi format — dipakai ulang oleh dialog ekspor bulanan.
class ExportFormatOption extends StatelessWidget {
  const ExportFormatOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.bodyBold)),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ));
  }
}
