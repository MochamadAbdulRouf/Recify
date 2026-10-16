import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Sesi akun aktif. Gerbang awal aplikasi membaca provider ini:
/// belum login → layar auth, sudah login → MainShell.
class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  static const _kSessionUserId = 'auth_current_user_id';

  UserModel? _user;
  bool _isLoading = true;
  bool _initialized = false;

  UserModel? get currentUser => _user;
  String? get currentUserId => _user?.id;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  /// Email untuk prefill kolom login sekali pakai (diisi layar kredensial).
  String? _prefillEmail;
  void setPrefillEmail(String email) => _prefillEmail = email;
  String? consumePrefillEmail() {
    final e = _prefillEmail;
    _prefillEmail = null;
    return e;
  }

  /// Muat sesi tersimpan (dipanggil sekali saat aplikasi dibuka).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_kSessionUserId);
      if (id != null && id.isNotEmpty) {
        _user = await _repository.getUserById(id);
        if (_user == null) {
          await prefs.remove(_kSessionUserId);
        }
      }
    } catch (_) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_kSessionUserId);
    } else {
      await prefs.setString(_kSessionUserId, userId);
    }
  }

  /// Daftar akun baru: TANPA sesi (user wajib login manual setelahnya).
  /// Mengembalikan akun agar pemanggil bisa tampilkan layar kredensial.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final user = await _repository.signUp(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    notifyListeners();
    return user;
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final user =
        await _repository.login(identifier: identifier, password: password);
    _user = user;
    await _persistSession(user.id);
    notifyListeners();
    return user;
  }

  /// Keluar: sesi dihapus, data akun tetap tersimpan di perangkat.
  Future<void> logout() async {
    _user = null;
    await _persistSession(null);
    notifyListeners();
  }

  /// Pindah ke akun lain yang sudah terbuka (sesi + flag login valid).
  Future<void> switchTo(UserModel user) async {
    _user = user;
    await _persistSession(user.id);
    notifyListeners();
  }

  /// Buka akun terkunci di switcher via password, lalu pindah ke sana.
  Future<UserModel> unlockAndSwitch({
    required String userId,
    required String password,
  }) async {
    final user =
        await _repository.unlockAccount(userId: userId, password: password);
    await switchTo(user);
    return user;
  }

  /// Semua akun terdaftar di perangkat (untuk popup switcher).
  Future<List<UserModel>> fetchAllUsers() => _repository.getAllUsers();

  /// Hapus akun + seluruh datanya secara permanen.
  Future<void> deleteAccount() async {
    final id = _user?.id;
    if (id == null) return;
    await _repository.deleteAccount(id);
    _user = null;
    await _persistSession(null);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? avatarPath}) async {
    final id = _user?.id;
    if (id == null) return;
    final updated =
        await _repository.updateProfile(id, name: name, avatarPath: avatarPath);
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
  }
}
