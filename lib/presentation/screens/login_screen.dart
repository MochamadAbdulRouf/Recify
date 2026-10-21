import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/auth_repository.dart';
import '../components/app_toast.dart';
import '../components/pressable.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import 'signup_screen.dart';

/// Masuk akun lokal. Konten khusus login: email + password + jalan
/// ke pendaftaran. Tanpa verifikasi email (100% offline).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final prefill = context.read<AuthProvider>().consumePrefillEmail();
    if (prefill != null && prefill.isNotEmpty) {
      _emailController.text = prefill;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final auth = context.read<AuthProvider>();
    final finance = context.read<FinanceProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      final (:user, :firstLogin) = await auth.login(
        identifier: _emailController.text,
        password: _passwordController.text,
      );
      // Toast dipanggil tanpa cek mounted: AppToast memakai overlay global
      // dan `s` sudah diambil di awal method — AuthGate bisa meng-unmount
      // layar login sebetis setelah login sukses (swap ke MainShell).
      AppToast.success(
        firstLogin
            ? s.loginFirstTime(user.name)
            : s.loginWelcomeBack(user.name),
      );
      await finance.setUser(user.id);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = s.authErrorMessage(e.code));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryCtaGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.wallet_rounded,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(s.authWelcomeBack,
                    style: AppTypography.headlineMd.copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Text(s.authWelcomeSubtitle,
                    style: AppTypography.bodyReg
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                Text(s.identifierField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _AuthField(
                  controller: _emailController,
                  hint: s.identifierHint,
                  keyboard: TextInputType.text,
                  onSubmit: _submit,
                ),
                const SizedBox(height: 14),
                Text(s.passwordField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _AuthField(
                  controller: _passwordController,
                  hint: s.passwordHint,
                  obscure: _obscure,
                  onSubmit: _submit,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 20,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 24),
                PressableScale(
                  child: GestureDetector(
                    onTap: _busy ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryCtaGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(s.loginButton,
                                style: AppTypography.bodyBold.copyWith(
                                    color: Colors.white, fontSize: 15)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.noAccountYet, style: AppTypography.caption),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                      child: Text(s.authCreateAccount,
                          style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(s.authOfflineNote,
                      style: AppTypography.caption.copyWith(fontSize: 11)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Field teks gaya kartu pengaturan (dipakai login & signup).
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        autocorrect: false,
        enableSuggestions: !obscure,
        style: AppTypography.bodyBold.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: suffix,
        ),
        onSubmitted: (_) => onSubmit?.call(),
      ),
    );
  }
}
