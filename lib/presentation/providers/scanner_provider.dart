import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/parsed_receipt_data.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/receipt_archive_manager.dart';
import '../../domain/ocr/gemini_receipt_parser.dart';
import '../../domain/ocr/indonesian_receipt_parser.dart';
import '../../domain/ocr/mlkit_receipt_scanner.dart';
import '../../domain/ocr/receipt_validator.dart';

enum ScannerState { idle, picking, scanning, parsing, validating, success, error }

/// SharedPreferences keys for OCR settings
class OcrPrefsKeys {
  static const String geminiApiKey = 'ocr_gemini_api_key';
  static const String useAiParser = 'ocr_use_ai_parser';
}

class ScannerProvider with ChangeNotifier {
  final MLKitReceiptScanner _ocrScanner = MLKitReceiptScanner();
  final IndonesianReceiptParser _regexParser = IndonesianReceiptParser();
  final GeminiReceiptParser _geminiParser = GeminiReceiptParser();
  final ReceiptArchiveManager _archiveManager = ReceiptArchiveManager.instance;
  final FinanceRepository _financeRepository = FinanceRepository();
  final ImagePicker _picker = ImagePicker();

  ScannerState _state = ScannerState.idle;
  String _errorMessage = '';
  File? _capturedImage;
  ParsedReceiptData? _parsedData;
  String? _rawOcrText;
  ValidationResult? _validationResult;

  /// Whether AI parser is enabled (user preference)
  bool _useAiParser = true;

  /// Whether a valid Gemini API key is configured
  bool _hasApiKey = false;

  ScannerState get state => _state;
  String get errorMessage => _errorMessage;
  File? get capturedImage => _capturedImage;
  ParsedReceiptData? get parsedData => _parsedData;
  ParsedReceiptData? get lastScanResult => _parsedData;
  String? get scannedReceiptImagePath => _capturedImage?.path;
  String? get rawOcrText => _rawOcrText;
  ValidationResult? get validationResult => _validationResult;
  bool get useAiParser => _useAiParser;
  bool get hasApiKey => _hasApiKey;

  /// Initialize AI parser settings from SharedPreferences.
  /// Call this once when the provider is first created.
  Future<void> initializeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useAiParser = prefs.getBool(OcrPrefsKeys.useAiParser) ?? true;
      final apiKey = prefs.getString(OcrPrefsKeys.geminiApiKey) ?? '';
      _hasApiKey = apiKey.isNotEmpty;

      if (_hasApiKey) {
        _geminiParser.initialize(apiKey);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load OCR settings: $e');
    }
  }

  /// Update the Gemini API key and persist it.
  Future<void> setGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OcrPrefsKeys.geminiApiKey, apiKey.trim());
    _hasApiKey = apiKey.trim().isNotEmpty;

    if (_hasApiKey) {
      _geminiParser.initialize(apiKey.trim());
    }
    notifyListeners();
  }

  /// Toggle AI parser on/off and persist the preference.
  Future<void> setUseAiParser(bool value) async {
    _useAiParser = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OcrPrefsKeys.useAiParser, value);
    notifyListeners();
  }

  /// Get the stored Gemini API key (for display in settings).
  Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OcrPrefsKeys.geminiApiKey) ?? '';
  }

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

      // ─────────────────────────────────────────────────────────────────────
      // Stage 1: OCR Text Extraction (ML Kit — always on-device)
      // ─────────────────────────────────────────────────────────────────────
      final rawText = await _ocrScanner.processImage(_capturedImage!);
      _rawOcrText = rawText;

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📋 OCR RAW TEXT:');
      debugPrint(rawText);
      debugPrint('═══════════════════════════════════════════');

      // ─────────────────────────────────────────────────────────────────────
      // Stage 2: Parse structured receipt data (Gemini LLM or Regex fallback)
      // ─────────────────────────────────────────────────────────────────────
      _state = ScannerState.parsing;
      notifyListeners();

      ParsedReceiptData parsed;
      if (_useAiParser && _hasApiKey && await _isOnline()) {
        // Online + AI enabled → Use Gemini LLM Parser
        try {
          debugPrint('🤖 Using Gemini AI parser...');
          parsed = await _geminiParser.parseOcrText(rawText, imagePath: _capturedImage!.path);
          debugPrint('✅ Gemini parser succeeded');
        } catch (e) {
          // Gemini failed → fallback to regex parser
          debugPrint('⚠️ Gemini parser failed: $e');
          debugPrint('🔄 Falling back to regex parser...');
          parsed = _regexParser.parse(rawText, imagePath: _capturedImage!.path);
          parsed = parsed.copyWith(parserSource: 'regex');
        }
      } else {
        // Offline or AI disabled → Use regex parser
        final reason = !_useAiParser
            ? 'AI parser disabled'
            : !_hasApiKey
                ? 'No API key configured'
                : 'Device offline';
        debugPrint('📝 Using regex parser ($reason)');
        parsed = _regexParser.parse(rawText, imagePath: _capturedImage!.path);
        parsed = parsed.copyWith(parserSource: 'regex');
      }

      // ─────────────────────────────────────────────────────────────────────
      // Stage 3: Validate parsed data (mathematical consistency check)
      // ─────────────────────────────────────────────────────────────────────
      _state = ScannerState.validating;
      notifyListeners();

      _validationResult = ReceiptValidator.validate(parsed);
      _parsedData = parsed.copyWith(validationStatus: _validationResult!.status);

      debugPrint('📊 PARSED RESULT (${_parsedData!.parserSource ?? "unknown"}):');
      debugPrint('  Merchant: ${_parsedData!.merchantName}');
      debugPrint('  Category: ${_parsedData!.suggestedCategory}');
      debugPrint('  Grand Total: ${_parsedData!.grandTotal}');
      debugPrint('  Subtotal: ${_parsedData!.subtotal}');
      debugPrint('  Tax: ${_parsedData!.tax}');
      debugPrint('  Discount: ${_parsedData!.discount}');
      debugPrint('  Items (${_parsedData!.items.length}):');
      for (final item in _parsedData!.items) {
        debugPrint('    - ${item.itemName}: ${item.quantity}x @ ${item.unitPrice} = ${item.totalPrice}');
      }
      debugPrint('  Validation: ${_validationResult!.status} — ${_validationResult!.message}');
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

  /// Check if the device has internet connectivity.
  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
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
      // Re-validate after manual edit
      _validationResult = ReceiptValidator.validate(_parsedData!);
      _parsedData = _parsedData!.copyWith(validationStatus: _validationResult!.status);
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
      // Re-validate after item edit
      _validationResult = ReceiptValidator.validate(_parsedData!);
      _parsedData = _parsedData!.copyWith(validationStatus: _validationResult!.status);
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (_parsedData != null && index >= 0 && index < _parsedData!.items.length) {
      final updatedList = List<ParsedReceiptItem>.from(_parsedData!.items);
      updatedList.removeAt(index);
      _parsedData = _parsedData!.copyWith(items: updatedList);
      // Re-validate after item removal
      _validationResult = ReceiptValidator.validate(_parsedData!);
      _parsedData = _parsedData!.copyWith(validationStatus: _validationResult!.status);
      notifyListeners();
    }
  }

  void addItem(ParsedReceiptItem item) {
    if (_parsedData != null) {
      final updatedList = List<ParsedReceiptItem>.from(_parsedData!.items)..add(item);
      _parsedData = _parsedData!.copyWith(items: updatedList);
      // Re-validate after item addition
      _validationResult = ReceiptValidator.validate(_parsedData!);
      _parsedData = _parsedData!.copyWith(validationStatus: _validationResult!.status);
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
      debugPrint('   Parser: ${_parsedData!.parserSource}, Validation: ${_parsedData!.validationStatus}');

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
    _validationResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrScanner.dispose();
    _geminiParser.dispose();
    super.dispose();
  }
}
