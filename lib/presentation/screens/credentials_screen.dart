import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../components/app_toast.dart';
import '../components/pressable.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';

/// Tampilkan kredensial akun baru 5 detik agar user bisa menyalin /
/// screenshot sebelum wajib login manual. Password tidak disimpan
/// di mana pun — hanya diteruskan dari layar signup saat ini.
class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  static const _kSeconds = 5;
  int _left = _kSeconds;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.success(AppStrings.of(context).accountCreated);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        _goLogin();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copyAll() async {
    final s = AppStrings.of(context);
    await Clipboard.setData(ClipboardData(
      text: 'Recify — info masuk akun\n'
          '${s.usernameField}: ${widget.name}\n'
          '${s.emailField}: ${widget.email}\n'
          '${s.passwordField}: ${widget.password}',
    ));
    AppToast.success(s.copiedMsg);
  }

  /// Selesai: pastikan tanpa sesi, kosongkan memori keuangan, kembali
  /// ke gerbang awal (tampil login dengan email terisi).
  Future<void> _goLogin() async {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    final auth = context.read<AuthProvider>();
    final finance = context.read<FinanceProvider>();
    auth.setPrefillEmail(widget.email);
    finance.clearUser();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryCtaGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.key_rounded,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(s.credTitle,
                      style: AppTypography.headlineMd.copyWith(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(s.credSubtitle,
                      style: AppTypography.bodyReg
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _CredRow(label: s.usernameField, value: widget.name),
                  const SizedBox(height: 12),
                  _CredRow(label: s.emailField, value: widget.email),
                  const SizedBox(height: 12),
                  Text(s.passwordField,
                      style: AppTypography.caption
                          .copyWith(fontSize: 10, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.statusPositiveBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.45)),
                    ),
                    child: Text(widget.password,
                        style: AppTypography.bodyBold
                            .copyWith(fontSize: 17, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 20),
                  PressableScale(
                    child: GestureDetector(
                      onTap: _copyAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh
                              .withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 18, color: AppColors.primaryLight),
                            const SizedBox(width: 8),
                            Text(s.copyAll,
                                style: AppTypography.bodyBold.copyWith(
                                    color: AppColors.primaryLight,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    child: GestureDetector(
                      onTap: _goLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryCtaGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(s.loginNow,
                              style: AppTypography.bodyBold
                                  .copyWith(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _left / _kSeconds,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(s.credRedirect(_left),
                        style: AppTypography.caption),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption
                .copyWith(fontSize: 10, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child:
              Text(value, style: AppTypography.bodyBold.copyWith(fontSize: 15)),
        ),
      ],
    );
  }
}
