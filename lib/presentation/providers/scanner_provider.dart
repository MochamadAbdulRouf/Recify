import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/parsed_receipt_data.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/receipt_archive_manager.dart';
import '../../domain/ocr/indonesian_receipt_parser.dart';
import '../../domain/ocr/mlkit_receipt_scanner.dart';

enum ScannerState { idle, picking, scanning, success, error }

class ScannerProvider with ChangeNotifier {
  final MLKitReceiptScanner _ocrScanner = MLKitReceiptScanner();
  final IndonesianReceiptParser _parser = IndonesianReceiptParser();
  final ReceiptArchiveManager _archiveManager = ReceiptArchiveManager.instance;
  final FinanceRepository _financeRepository = FinanceRepository();
  final ImagePicker _picker = ImagePicker();

  ScannerState _state = ScannerState.idle;
  String _errorMessage = '';
  File? _capturedImage;
  ParsedReceiptData? _parsedData;
  String? _rawOcrText;

  ScannerState get state => _state;
  String get errorMessage => _errorMessage;
  File? get capturedImage => _capturedImage;
  ParsedReceiptData? get parsedData => _parsedData;
  ParsedReceiptData? get lastScanResult => _parsedData;
  String? get scannedReceiptImagePath => _capturedImage?.path;
  String? get rawOcrText => _rawOcrText;

  Future<void> pickAndScanReceipt(ImageSource source) async {
    await pickImageAndScan(source: source);
  }

  Future<void> pickImageAndScan({required ImageSource source}) async {
    try {
      _state = ScannerState.picking;
      notifyListeners();

      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 2400,  // Increased for better OCR quality
        maxHeight: 2400,
        imageQuality: 92, // Higher quality for better text recognition
      );

      if (photo == null) {
        _state = ScannerState.idle;
        notifyListeners();
        return;
      }

      _capturedImage = File(photo.path);
      _state = ScannerState.scanning;
      notifyListeners();

      // On-Device OCR text extraction with layout reconstruction
      final rawText = await _ocrScanner.processImage(_capturedImage!);
      _rawOcrText = rawText;

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📋 OCR RAW TEXT:');
      debugPrint(rawText);
      debugPrint('═══════════════════════════════════════════');

      // Parse structured receipt from OCR text
      _parsedData = _parser.parse(rawText, imagePath: _capturedImage!.path);

      debugPrint('📊 PARSED RESULT:');
      debugPrint('  Merchant: ${_parsedData!.merchantName}');
      debugPrint('  Category: ${_parsedData!.suggestedCategory}');
      debugPrint('  Grand Total: ${_parsedData!.grandTotal}');
      debugPrint('  Items (${_parsedData!.items.length}):');
      for (final item in _parsedData!.items) {
        debugPrint('    - ${item.itemName}: ${item.quantity}x @ ${item.unitPrice} = ${item.totalPrice}');
      }
      debugPrint('═══════════════════════════════════════════');

      _state = ScannerState.success;
      notifyListeners();
    } catch (e, stackTrace) {
      _state = ScannerState.error;
      _errorMessage = 'Gagal memproses struk: $e';
      debugPrint('❌ Scanner Error: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  void updateMerchantName(String name) {
    if (_parsedData != null) {
      _parsedData = _parsedData!.copyWith(merchantName: name);
      notifyListeners();
    }
  }

  void updateGrandTotal(double total) {
    if (_parsedData != null) {
      _parsedData = _parsedData!.copyWith(grandTotal: total);
      notifyListeners();
    }
  }

  void updateCategory(String categoryId) {
    if (_parsedData != null) {
      _parsedData = _parsedData!.copyWith(suggestedCategory: categoryId);
      notifyListeners();
    }
  }

  void updateItem(int index, ParsedReceiptItem updatedItem) {
    if (_parsedData != null && index >= 0 && index < _parsedData!.items.length) {
      final updatedList = List<ParsedReceiptItem>.from(_parsedData!.items);
      updatedList[index] = updatedItem;
      _parsedData = _parsedData!.copyWith(items: updatedList);
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (_parsedData != null && index >= 0 && index < _parsedData!.items.length) {
      final updatedList = List<ParsedReceiptItem>.from(_parsedData!.items);
      updatedList.removeAt(index);
      _parsedData = _parsedData!.copyWith(items: updatedList);
      notifyListeners();
    }
  }

  void addItem(ParsedReceiptItem item) {
    if (_parsedData != null) {
      final updatedList = List<ParsedReceiptItem>.from(_parsedData!.items)..add(item);
      _parsedData = _parsedData!.copyWith(items: updatedList);
      notifyListeners();
    }
  }

  Future<void> saveVerifiedTransaction({
    required String walletId,
    String? customNotes,
  }) async {
    if (_parsedData == null) {
      debugPrint('❌ saveVerifiedTransaction: No parsed data available');
      return;
    }

    try {
      String? archivedPath;
      if (_capturedImage != null) {
        archivedPath = await _archiveManager.saveCompressedReceipt(_capturedImage!);
      }

      final txId = const Uuid().v4();
      final transaction = TransactionModel(
        id: txId,
        walletId: walletId,
        categoryId: _parsedData!.suggestedCategory,
        type: 'EXPENSE',
        amount: _parsedData!.grandTotal,
        transactionDate: _parsedData!.transactionDate.millisecondsSinceEpoch,
        merchantName: _parsedData!.merchantName,
        receiptImagePath: archivedPath,
        notes: customNotes ?? 'Scan Nota: ${_parsedData!.merchantName}',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final items = _parsedData!.items.map((i) {
        return TransactionItemModel(
          id: const Uuid().v4(),
          transactionId: txId,
          itemName: i.itemName,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          totalPrice: i.totalPrice,
          categoryId: _parsedData!.suggestedCategory,
        );
      }).toList();

      await _financeRepository.recordTransaction(transaction, items);

      debugPrint('✅ Transaction saved: $txId (${_parsedData!.merchantName})');
      debugPrint('   Amount: ${_parsedData!.grandTotal}, Items: ${items.length}');

      reset();
    } catch (e, stackTrace) {
      debugPrint('❌ saveVerifiedTransaction Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Rethrow so the caller can show error UI
    }
  }

  void reset() {
    _state = ScannerState.idle;
    _errorMessage = '';
    _capturedImage = null;
    _parsedData = null;
    _rawOcrText = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrScanner.dispose();
    super.dispose();
  }
}
