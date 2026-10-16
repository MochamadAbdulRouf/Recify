import '../../data/local/database_helper.dart';

/// Profil akun aktif — satu-satunya sumber nama & avatar adalah tabel
/// `users` (terikat akun, bukan file global), jadi tiap akun punya
/// profilnya sendiri dan tidak bocor ke akun lain.
class ProfileService {
  static final _dbHelper = DatabaseHelper.instance;

  static Future<String> getUserName(String userId) async {
    final user = await _dbHelper.getUserById(userId);
    final name = user?.name.trim() ?? '';
    return name.isNotEmpty ? name : 'Pengguna Recify';
  }

  static Future<void> setUserName(String userId, String name) async {
    await _dbHelper.updateUserProfile(userId, name: name.trim());
  }

  static Future<String?> getAvatarPath(String userId) async {
    final user = await _dbHelper.getUserById(userId);
    return user?.avatarPath;
  }

  static Future<void> setAvatarPath(String userId, String? path) async {
    await _dbHelper.updateUserProfile(userId, avatarPath: path);
  }
}
