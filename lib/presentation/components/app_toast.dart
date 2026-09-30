import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum _ToastKind { success, error }

/// Toast global untuk notifikasi simpan data (sukses/gagal).
///
/// Dipanggil dari mana saja tanpa context:
/// ```dart
/// AppToast.success(s.savedTransaction(name, amount));
/// AppToast.error(s.saveFailed('$e'));
/// ```
/// Muncul di atas layar, slide-in 300ms, auto-dismiss ~3.5s,
/// bisa ditutup manual. Warna lewat token AppColors → ikut tema
/// light/dark otomatis.
class AppToast {
  AppToast._();

  /// Dipasang di MaterialApp(navigatorKey: ...).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(String message) => _show(_ToastKind.success, message);
  static void error(String message) => _show(_ToastKind.error, message);

  static void _show(_ToastKind kind, String message) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _timer?.cancel();
    _entry?.remove();

    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        kind: kind,
        message: message,
        onDismiss: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 3500), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.kind,
    required this.message,
    required this.onDismiss,
  });

  final _ToastKind kind;
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Satu frame off-screen dulu supaya AnimatedSlide punya titik awal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isError = widget.kind == _ToastKind.error;
    final accent = isError ? AppColors.error : AppColors.statusPositive;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, -1.2),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isError
                            ? Icons.error_rounded
                            : Icons.check_circle_rounded,
                        size: 20,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isError
                                  ? s.toastErrorTitle
                                  : s.toastSuccessTitle,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isError
                                    ? AppColors.errorText
                                    : AppColors.statusPositive,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
