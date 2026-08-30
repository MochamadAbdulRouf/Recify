import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';

class ReportExporter {
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

  // --- Export to CSV ---
  static Future<File> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    final exportDir = await _getPublicDownloadsDirectory();
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(join(exportDir.path, 'Recify_Laporan_$timeStamp.csv'));

    List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'ID Transaksi',
      'Tanggal & Waktu',
      'Tipe',
      'Nama Tempat / Merchant',
      'Kategori',
      'Dompet / Sumber Dana',
      'Nominal (Rp)',
      'Catatan',
      'Rincian Item',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tx.transactionDate));
      final itemsSummary = tx.items.map((i) => '${i.itemName} (${i.quantity}x Rp${i.unitPrice.toInt()})').join('; ');

      rows.add([
        tx.id,
        dateStr,
        tx.type == 'EXPENSE' ? 'Pengeluaran' : (tx.type == 'INCOME' ? 'Pemasukan' : 'Transfer'),
        tx.merchantName ?? '',
        tx.category?.name ?? 'Umum',
        tx.wallet?.name ?? 'Utama',
        tx.amount,
        tx.notes ?? '',
        itemsSummary,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csvData);
    return file;
  }

  // --- Export to Excel (.xlsx) ---
  static Future<File> exportTransactionsToExcel(List<TransactionModel> transactions) async {
    final exportDir = await _getPublicDownloadsDirectory();
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(join(exportDir.path, 'Recify_Laporan_$timeStamp.xlsx'));

    final excel = xl.Excel.createExcel();
    final sheetName = 'Laporan Recify';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Header styling
    final headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#2F6BFF'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    final headers = [
      'No',
      'Tanggal & Waktu',
      'Tipe',
      'Nama Tempat / Merchant',
      'Kategori',
      'Dompet / Sumber Dana',
      'Nominal (Rp)',
      'Catatan',
      'Rincian Item',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = xl.TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final dateStr = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tx.transactionDate));
      final itemsSummary = tx.items.map((it) => '${it.itemName} (${it.quantity}x Rp${it.unitPrice.toInt()})').join('; ');
      final rowIndex = i + 1;

      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = xl.IntCellValue(i + 1);
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = xl.TextCellValue(dateStr);
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          xl.TextCellValue(tx.type == 'EXPENSE' ? 'Pengeluaran' : (tx.type == 'INCOME' ? 'Pemasukan' : 'Transfer'));
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = xl.TextCellValue(tx.merchantName ?? '-');
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = xl.TextCellValue(tx.category?.name ?? 'Umum');
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = xl.TextCellValue(tx.wallet?.name ?? 'Utama');
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = xl.DoubleCellValue(tx.amount);
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = xl.TextCellValue(tx.notes ?? '');
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = xl.TextCellValue(itemsSummary);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }
}
