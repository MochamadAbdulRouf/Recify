import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyUserName = 'user_profile_name';
  static const String _keyAvatarPath = 'user_avatar_path';

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Pengguna Recify';
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAvatarPath);
  }

  static Future<void> setAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyAvatarPath);
    } else {
      await prefs.setString(_keyAvatarPath, path);
    }
  }
}
