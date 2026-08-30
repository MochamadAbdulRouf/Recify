import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';

class ReportExporter {
  static Future<File> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    Directory? exportDir;
    try {
      exportDir = await getExternalStorageDirectory();
    } catch (_) {}
    exportDir ??= await getApplicationDocumentsDirectory();

    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(join(exportDir.path, 'Recify_Transactions_$timeStamp.csv'));

    List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'Transaction ID',
      'Date',
      'Type',
      'Merchant',
      'Category',
      'Wallet',
      'Amount',
      'Notes',
      'Items Breakdown',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tx.transactionDate));
      final itemsSummary = tx.items.map((i) => '${i.itemName} (${i.quantity}x Rp${i.unitPrice.toInt()})').join('; ');

      rows.add([
        tx.id,
        dateStr,
        tx.type,
        tx.merchantName ?? '',
        tx.category?.name ?? 'Uncategorized',
        tx.wallet?.name ?? 'Unknown',
        tx.amount,
        tx.notes ?? '',
        itemsSummary,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csvData);
    return file;
  }
}
