import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/auth_repository.dart';
import '../components/pressable.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import 'credentials_screen.dart';

/// Daftar akun lokal. Konten khusus signup: nama + email + password +
/// konfirmasi. Akun baru langsung dapat ruang data fresh (kategori
/// template, dompet Rp 0). Tanpa verifikasi email (100% offline).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await auth.signUp(
        name: name,
        email: email,
        password: password,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      // Tanpa auto-login: tampilkan kredensial 5 detik agar disalin,
      // lalu user wajib login manual.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CredentialsScreen(
            name: name,
            email: email,
            password: password,
          ),
        ),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.authCreateAccount,
                    style: AppTypography.headlineMd.copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Text(s.authCreateSubtitle,
                    style: AppTypography.bodyReg
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                Text(s.usernameField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _SignUpField(controller: _nameController, hint: s.usernameHint),
                const SizedBox(height: 14),
                Text(s.emailField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _SignUpField(
                  controller: _emailController,
                  hint: s.emailHint,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                Text(s.passwordField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _SignUpField(
                  controller: _passwordController,
                  hint: s.passwordHint,
                  obscure: _obscure,
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
                const SizedBox(height: 14),
                Text(s.confirmPasswordField,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                _SignUpField(
                  controller: _confirmController,
                  hint: s.confirmPasswordHint,
                  obscure: _obscure,
                  onSubmit: _submit,
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
                            : Text(s.signupButton,
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
                    Text(s.haveAccount, style: AppTypography.caption),
                    GestureDetector(
                      onTap: () async {
                        // "Sudah punya akun" → ke LoginScreen. Bila dipush
                        // dari switch sheet dengan sesi aktif, akhiri sesi
                        // dulu agar AuthGate menampilkan login, bukan app
                        // akun sebelumnya; pop saja cukup bila masuk dari
                        // LoginScreen.
                        final auth = context.read<AuthProvider>();
                        final finance = context.read<FinanceProvider>();
                        if (auth.isLoggedIn) {
                          finance.clearUser();
                          await auth.logout();
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(s.loginButton,
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

class _SignUpField extends StatelessWidget {
  const _SignUpField({
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
