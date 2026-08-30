import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/finance_repository.dart';

class BackupManager {
  static final FinanceRepository _repository = FinanceRepository();

  static Future<Directory> _getPublicDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        return downloadDir;
      }
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty && extDirs.first.existsSync()) {
          return extDirs.first;
        }
      } catch (_) {}
    }
    return await getApplicationDocumentsDirectory();
  }

  static Future<File> createBackupFile() async {
    final data = await _repository.getAllDataForBackup();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final downloadsDir = await _getPublicDownloadsDirectory();
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile = File(join(downloadsDir.path, 'Recify_Backup_$timeStamp.json'));

    await backupFile.writeAsString(jsonString);
    return backupFile;
  }

  static Future<bool> restoreFromBackupFile(File file) async {
    if (!file.existsSync()) {
      throw Exception('File backup tidak ditemukan.');
    }

    final content = await file.readAsString();
    final dynamic decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format file cadangan tidak valid.');
    }

    if (!decoded.containsKey('wallets') && !decoded.containsKey('transactions')) {
      throw Exception('File ini bukan file cadangan Recify yang sah.');
    }

    await _repository.restoreAllData(decoded);
    return true;
  }
}
