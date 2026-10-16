import 'package:uuid/uuid.dart';
import '../../core/utils/password_hasher.dart';
import '../local/database_helper.dart';
import '../models/user_model.dart';

/// Kode error auth — UI memetakan ke teks via AppStrings (ID/EN).
enum AuthError {
  emptyName,
  invalidEmail,
  weakPassword,
  passwordMismatch,
  emailTaken,
  userNotFound,
  wrongPassword,
}

class AuthException implements Exception {
  final AuthError code;
  AuthException(this.code);
}

/// Daftar & masuk akun lokal (100% offline, tanpa verifikasi email).
/// Tiap akun baru langsung di-seed ruang datanya sendiri.
class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const _uuid = Uuid();

  static final _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = PasswordHasher.normalizeEmail(email);
    if (cleanName.isEmpty) throw AuthException(AuthError.emptyName);
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw AuthException(AuthError.invalidEmail);
    }
    if (password.length < 6) throw AuthException(AuthError.weakPassword);
    if (password != confirmPassword) {
      throw AuthException(AuthError.passwordMismatch);
    }
    final existing = await _dbHelper.getUserByEmail(cleanEmail);
    if (existing != null) throw AuthException(AuthError.emailTaken);

    final salt = PasswordHasher.newSalt();
    final user = UserModel(
      id: _uuid.v4(),
      email: cleanEmail,
      passwordHash: PasswordHasher.hash(password, salt),
      salt: salt,
      name: cleanName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _dbHelper.insertUser(user);
    await _dbHelper.seedNewUserData(user.id);
    return user;
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final clean = identifier.trim();
    UserModel? user;
    if (_emailRegex.hasMatch(clean.toLowerCase())) {
      user = await _dbHelper.getUserByEmail(clean);
    } else {
      // Bukan email → anggap username (nama akun).
      user = await _dbHelper.getUserByName(clean);
    }
    if (user == null) throw AuthException(AuthError.userNotFound);
    final ok = PasswordHasher.verify(password, user.salt, user.passwordHash);
    if (!ok) throw AuthException(AuthError.wrongPassword);
    await _dbHelper.setHasLoggedIn(user.id);
    return (await _dbHelper.getUserById(user.id)) ?? user;
  }

  Future<UserModel?> getUserById(String id) => _dbHelper.getUserById(id);

  Future<List<UserModel>> getAllUsers() => _dbHelper.getAllUsers();

  /// Verifikasi password untuk membuka akun di switcher tanpa login ulang.
  /// Sukses → tandai sudah-pernah-login + kembalikan akunnya.
  Future<UserModel> unlockAccount({
    required String userId,
    required String password,
  }) async {
    final user = await _dbHelper.getUserById(userId);
    if (user == null) throw AuthException(AuthError.userNotFound);
    final ok = PasswordHasher.verify(password, user.salt, user.passwordHash);
    if (!ok) throw AuthException(AuthError.wrongPassword);
    await _dbHelper.setHasLoggedIn(user.id);
    return (await _dbHelper.getUserById(user.id)) ?? user;
  }

  Future<void> deleteAccount(String userId) =>
      _dbHelper.deleteUserWithData(userId);

  Future<UserModel?> updateProfile(String userId,
      {String? name, String? avatarPath}) async {
    await _dbHelper.updateUserProfile(userId,
        name: name, avatarPath: avatarPath);
    return _dbHelper.getUserById(userId);
  }
}
