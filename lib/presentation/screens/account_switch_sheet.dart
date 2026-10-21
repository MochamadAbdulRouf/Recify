import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../components/app_toast.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import 'signup_screen.dart';

/// Popup pilih akun ( Pengaturan → Ganti Akun ). Menampilkan semua akun
/// yang pernah dibuat di perangkat: yang sudah pernah login manual bisa
/// pindah langsung, yang belum wajib buka kunci via password dulu.
Future<void> showAccountSwitchSheet(BuildContext context) {
  final s = AppStrings.of(context);
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(s.switchTitle, style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              Text(s.switchAccountSubtitle, style: AppTypography.caption),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<UserModel>>(
                  future: ctx.read<AuthProvider>().fetchAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final users = snapshot.data!;
                    final currentId = ctx.watch<AuthProvider>().currentUserId;
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == users.length) {
                          return _AddAccountRow(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                          );
                        }
                        final user = users[i];
                        final isCurrent = user.id == currentId;
                        return _AccountRow(
                          user: user,
                          isCurrent: isCurrent,
                          onTap: () =>
                              _onPickAccount(context, ctx, user, isCurrent),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _onPickAccount(
  BuildContext context,
  BuildContext sheetCtx,
  UserModel user,
  bool isCurrent,
) async {
  if (isCurrent) {
    Navigator.pop(sheetCtx);
    return;
  }
  final s = AppStrings.of(context);
  final auth = context.read<AuthProvider>();
  final finance = context.read<FinanceProvider>();
  if (user.hasLoggedIn) {
    // Sudah pernah login manual → pindah langsung tanpa password.
    await auth.switchTo(user);
    await finance.setUser(user.id);
    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    AppToast.success(s.accountSwitched(user.name));
    return;
  }
  // Belum pernah login → wajib buka kunci via password dulu.
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (_) => _UnlockDialog(user: user),
  );
  if (unlocked == true) {
    final fresh = auth.currentUser;
    if (fresh != null) {
      await finance.setUser(fresh.id);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      AppToast.success(s.accountSwitched(fresh.name));
    } else if (sheetCtx.mounted) {
      Navigator.pop(sheetCtx);
    }
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.user,
    required this.isCurrent,
    required this.onTap,
  });

  final UserModel user;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial =
        user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primaryLight : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryCtaGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(initial,
                    style: AppTypography.bodyBold
                        .copyWith(color: Colors.white, fontSize: 17)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: AppTypography.bodyBold,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.check_circle_rounded,
                  size: 22, color: AppColors.secondary)
            else if (!user.hasLoggedIn)
              Icon(Icons.lock_rounded,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(s.addAccount,
                style: AppTypography.bodyBold
                    .copyWith(color: AppColors.primaryLight)),
          ],
        ),
      ),
    );
  }
}

/// Dialog password untuk membuka akun yang belum pernah login manual.
class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog({required this.user});

  final UserModel user;

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.unlockAndSwitch(
        userId: widget.user.id,
        password: _passwordController.text,
      );
      if (mounted) Navigator.pop(context, true);
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
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.unlockTitle, style: AppTypography.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.unlockSubtitle(widget.user.name),
              style: AppTypography.caption),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscure,
              autofocus: true,
              style: AppTypography.bodyBold.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: s.passwordHint,
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: AppTypography.caption.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child:
              Text(s.cancel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(s.loginButton,
                  style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
