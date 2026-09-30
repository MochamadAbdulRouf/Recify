import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'export_format_dialog.dart';

/// Hasil pilihan user: bulan + tahun + format.
class MonthlyExportSelection {
  const MonthlyExportSelection({
    required this.month,
    required this.year,
    required this.format,
  });

  final int month;
  final int year;
  final ExportFormat format;
}

/// Dialog ekspor bulanan: pilih bulan + tahun + format Excel/CSV.
/// Opsi format pakai ulang [ExportFormatOption] dari dialog standar.
///
/// Kembalikan null kalau batal. Validasi "bulan kosong" dilakukan
/// pemanggil (provider lempar StateError) supaya pesan tampil di dialog.
class MonthlyExportDialog extends StatefulWidget {
  const MonthlyExportDialog({super.key});

  static Future<MonthlyExportSelection?> show(BuildContext context) {
    return showDialog<MonthlyExportSelection>(
      context: context,
      builder: (_) => const MonthlyExportDialog(),
    );
  }

  @override
  State<MonthlyExportDialog> createState() => _MonthlyExportDialogState();
}

class _MonthlyExportDialogState extends State<MonthlyExportDialog> {
  late int _month;
  late int _year;
  ExportFormat _format = ExportFormat.excel;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  List<int> get _years {
    final current = DateTime.now().year;
    return List.generate(6, (i) => current - i);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.exportTaxReport, style: AppTypography.titleMedium),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _LabelledDropdown<int>(
                      label: s.exportMonthLabel,
                      value: _month,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(s.monthsShort[i]),
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        if (v != null) {
                          _month = v;
                          _error = null;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _LabelledDropdown<int>(
                      label: s.exportYearLabel,
                      value: _year,
                      items: _years
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        if (v != null) {
                          _year = v;
                          _error = null;
                        }
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ExportFormatOption(
                icon: Icons.table_chart_outlined,
                label: s.exportFormatExcel,
                selected: _format == ExportFormat.excel,
                onTap: () => setState(() => _format = ExportFormat.excel),
              ),
              const SizedBox(height: 8),
              ExportFormatOption(
                icon: Icons.description_outlined,
                label: s.exportFormatCsv,
                selected: _format == ExportFormat.csv,
                onTap: () => setState(() => _format = ExportFormat.csv),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            MonthlyExportSelection(
                month: _month, year: _year, format: _format),
          ),
          child: Text(s.downloadAction),
        ),
      ],
    );
  }
}

class _LabelledDropdown<T> extends StatelessWidget {
  const _LabelledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.bgSurfaceElevated,
            style: AppTypography.bodyBold,
          ),
        ),
      ],
    );
  }
}
