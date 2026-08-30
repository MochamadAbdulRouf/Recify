import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReceiptArchiveManager {
  static final ReceiptArchiveManager instance = ReceiptArchiveManager._init();
  ReceiptArchiveManager._init();

  Future<Directory> get _receiptsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(join(appDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  Future<String> saveCompressedReceipt(File sourceFile) async {
    final targetDir = await _receiptsDirectory;
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final uniqueId = const Uuid().v4().substring(0, 6);
    final targetFileName = 'REC_${timeStamp}_$uniqueId.jpg';
    final targetPath = join(targetDir.path, targetFileName);

    // Copy file to target path
    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  Future<File?> getReceiptFile(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }
}
