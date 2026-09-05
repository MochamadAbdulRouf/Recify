import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/scanner_provider.dart';

enum _StepStatus { pending, active, done }

/// Live progress dialog shown while a receipt is being scanned & parsed.
///
/// Watches [ScannerProvider] and mirrors its [ScannerState] into a
/// 3-step indicator:
///   1. Memindai teks (OCR — ML Kit, on-device)
///   2. AI menganalisis struk (Gemini) / Parsing offline (regex)
///   3. Validasi perhitungan
///
/// The dialog is purely a display: the caller opens it before
/// `pickAndScanReceipt()` and closes it after the future completes.
class ScanProgressDialog extends StatelessWidget {
  const ScanProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerProvider>();
    final state = scanner.state;
    final useAi = scanner.useAiParser && scanner.hasApiKey;
    final isError = state == ScannerState.error;

    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError ? Icons.error_outline_rounded : Icons.document_scanner_rounded,
                  color: isError ? AppColors.error : AppColors.primaryLight,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(isError ? 'Gagal Memproses Nota' : 'Memproses Nota', style: AppTypography.titleMedium),
              ],
            ),
            const SizedBox(height: 18),
            _StepRow(
              label: 'Memindai teks (OCR on-device)',
              status: _statusForStep1(state),
            ),
            const SizedBox(height: 14),
            _StepRow(
              label: useAi ? 'AI menganalisis struk (Gemini)' : 'Parsing offline (regex)',
              status: _statusForStep2(state),
            ),
            const SizedBox(height: 14),
            _StepRow(
              label: 'Validasi perhitungan',
              status: _statusForStep3(state),
            ),
            if (isError) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  scanner.errorMessage.isEmpty ? 'Terjadi kesalahan saat memproses nota.' : scanner.errorMessage,
                  style: AppTypography.caption.copyWith(color: AppColors.error, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Text(
                _footerHint(state),
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StepStatus _statusForStep1(ScannerState state) {
    switch (state) {
      case ScannerState.idle:
      case ScannerState.picking:
        return _StepStatus.pending;
      case ScannerState.scanning:
        return _StepStatus.active;
      case ScannerState.parsing:
      case ScannerState.validating:
      case ScannerState.success:
        return _StepStatus.done;
      case ScannerState.error:
        return _StepStatus.pending;
    }
  }

  _StepStatus _statusForStep2(ScannerState state) {
    switch (state) {
      case ScannerState.parsing:
        return _StepStatus.active;
      case ScannerState.validating:
      case ScannerState.success:
        return _StepStatus.done;
      default:
        return _StepStatus.pending;
    }
  }

  _StepStatus _statusForStep3(ScannerState state) {
    switch (state) {
      case ScannerState.validating:
        return _StepStatus.active;
      case ScannerState.success:
        return _StepStatus.done;
      default:
        return _StepStatus.pending;
    }
  }

  String _footerHint(ScannerState state) {
    switch (state) {
      case ScannerState.picking:
      case ScannerState.scanning:
        return 'Membaca teks dari foto nota...';
      case ScannerState.parsing:
        return 'Analisis AI biasanya 3–15 detik...';
      case ScannerState.validating:
        return 'Hampir selesai...';
      case ScannerState.success:
        return 'Selesai!';
      case ScannerState.error:
      case ScannerState.idle:
        return '';
    }
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final _StepStatus status;

  const _StepRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Widget leading;
    switch (status) {
      case _StepStatus.done:
        textColor = AppColors.secondary;
        leading = const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.secondary);
        break;
      case _StepStatus.active:
        textColor = AppColors.textPrimary;
        leading = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryLight),
        );
        break;
      case _StepStatus.pending:
        textColor = AppColors.textSecondary;
        leading = const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.outlineVariant);
        break;
    }

    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyBold.copyWith(color: textColor, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
