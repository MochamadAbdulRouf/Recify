import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

/// Gerbang awal aplikasi: loading sesi → login / shell utama.
/// Menghubungkan akun aktif ke FinanceProvider tepat sekali per sesi.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _wiredUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryCtaGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child:
                const Icon(Icons.wallet_rounded, size: 36, color: Colors.white),
          ),
        ),
      );
    }

    final user = auth.currentUser;
    if (user == null) {
      _wiredUserId = null;
      return const LoginScreen();
    }

    // Hubungkan ruang data akun tepat sekali (bukan tiap rebuild).
    if (_wiredUserId != user.id) {
      _wiredUserId = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FinanceProvider>().setUser(user.id);
      });
    }
    // ignore: prefer_const_constructors — non-const disengaja (cascade rebuild tema/locale)
    return MainShellScreen();
  }
}
