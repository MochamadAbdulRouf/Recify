import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ProfileService {
  static Future<File> _getProfileFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, 'user_profile.json'));
  }

  static Future<Map<String, dynamic>> _readData() async {
    try {
      final file = await _getProfileFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {'name': 'Pengguna Recify', 'avatar_path': null};
  }

  static Future<void> _writeData(Map<String, dynamic> data) async {
    try {
      final file = await _getProfileFile();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<String> getUserName() async {
    final data = await _readData();
    return (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : 'Pengguna Recify';
  }

  static Future<void> setUserName(String name) async {
    final data = await _readData();
    data['name'] = name.trim();
    await _writeData(data);
  }

  static Future<String?> getAvatarPath() async {
    final data = await _readData();
    return data['avatar_path'] as String?;
  }

  static Future<void> setAvatarPath(String? path) async {
    final data = await _readData();
    data['avatar_path'] = path;
    await _writeData(data);
  }
}
