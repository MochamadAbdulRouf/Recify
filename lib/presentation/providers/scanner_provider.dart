import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../data/models/parsed_receipt_data.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/receipt_archive_manager.dart';
import '../../domain/ocr/gemini_models.dart';
import '../../domain/ocr/gemini_receipt_parser.dart';
import '../../domain/ocr/indonesian_receipt_parser.dart';
import '../../domain/ocr/mlkit_receipt_scanner.dart';
import '../../domain/ocr/receipt_validator.dart';

enum ScannerState { idle, picking, scanning, parsing, validating, success, error }

/// SharedPreferences keys for OCR settings
class OcrPrefsKeys {
  static const String geminiApiKey = 'ocr_gemini_api_key'; // legacy single key
  static const String geminiApiKeys = 'ocr_gemini_api_keys'; // JSON list
  static const String geminiActiveKey = 'ocr_gemini_active_key'; // index
  static const String geminiModel = 'ocr_gemini_model';
  static const String quotaBlocked = 'ocr_quota_blocked'; // JSON {key: ms}
  static const String keyCooldown = 'ocr_key_cooldown'; // JSON {index: ms}
  static const String badKeys = 'ocr_bad_keys'; // JSON list<int>
  static const String useAiParser = 'ocr_use_ai_parser';
}

/// Jenis notifikasi satu kali per scan — dikonsumsi caller jadi toast.
enum ScanNoticeKind { quota, overload, config, allFailed, keySwitch }

class ScanNotice {
  const ScanNotice(
    this.kind, {
    this.model,
    this.fromKey,
    this.toKey,
    this.retry,
    this.reason,
  });

  final ScanNoticeKind kind;

  /// Model kena kuota (kind.quota).
  final String? model;

  /// Nomor key 1-based (kind.config / kind.keySwitch).
  final int? fromKey;
  final int? toKey;

  /// Sisa waktu reset kuota (kind.quota).
  final Duration? retry;

  /// Alasan pindah key: 'overload' | 'limit' | 'config' (kind.keySwitch).
  final String? reason;
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

  /// Multi API keys — index aktif dipakai untuk request Gemini.
  List<String> _apiKeys = [];
  int _activeKeyIndex = 0;

  /// Model Gemini aktif (lihat gemini_models.dart).
  String _modelId = defaultGeminiModelId;

  /// Blokir kuota per '$keyIndex|$model' → kapan bisa dipakai lagi (UTC ms).
  /// Hanya untuk key aktif — survive restart via prefs.
  final Map<String, int> _quotaBlockedUntil = {};

  /// Notifikasi scan terakhir (kuota/gangguan/key) — dikonsumsi caller
  /// menjadi toast sekali setelah scan selesai (provider tanpa context).
  final List<ScanNotice> _lastScanNotices = [];
  List<ScanNotice> get lastScanNotices => List.unmodifiable(_lastScanNotices);
  void clearScanNotices() => _lastScanNotices.clear();

  /// Status ganti key aktif — tampil LIVE di ScanProgressDialog selama
  /// proses pindah; direset di awal & akhir scan.
  ({int from, int to, String reason})? scanStatusNote;
  void _resetScanStatusNote() => scanStatusNote = null;

  /// Key bermasalah permanen (error konfigurasi 400/403).
  final Set<int> _badKeys = {};

  /// Cooldown sementara key (gangguan 5xx → 2 menit). Epoch ms.
  final Map<int, int> _keyCooldownUntil = {};

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

  /// Daftar key (apa adanya — UI yang me-mask).
  List<String> get apiKeys => List.unmodifiable(_apiKeys);
  int get activeKeyIndex => _activeKeyIndex;
  String get modelId => _modelId;
  GeminiModelOption? get activeModel => geminiModelById(_modelId);

  /// Label key aktif untuk UI: '••••' + 4 char terakhir.
  String get activeKeyLabel {
    if (_apiKeys.isEmpty) return '';
    final k = _apiKeys[_activeKeyIndex.clamp(0, _apiKeys.length - 1)];
    return k.length <= 4 ? '••••' : '••••${k.substring(k.length - 4)}';
  }

  String _quotaKey(String model) => '$_activeKeyIndex|$model';

  /// True bila model ini diblokir kuota di key aktif (auto-prune kedaluwarsa).
  bool isModelBlocked(String model) {
    final until = _quotaBlockedUntil[_quotaKey(model)];
    if (until == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= until) {
      _quotaBlockedUntil.remove(_quotaKey(model));
      return false;
    }
    return true;
  }

  /// Sisa waktu blokir, atau null bila tidak diblokir.
  Duration? quotaRemaining(String model) {
    final until = _quotaBlockedUntil[_quotaKey(model)];
    if (until == null) return null;
    final left =
        until - DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) {
      _quotaBlockedUntil.remove(_quotaKey(model));
      return null;
    }
    return Duration(milliseconds: left);
  }

  Future<void> _persistQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    _quotaBlockedUntil.removeWhere((_, until) => until <= now);
    await prefs.setString(OcrPrefsKeys.quotaBlocked, jsonEncode(_quotaBlockedUntil));
  }

  /// Persist kesehatan key (cooldown gangguan + key bermasalah).
  Future<void> _persistKeyHealth() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    _keyCooldownUntil.removeWhere((_, until) => until <= now);
    await prefs.setString(
        OcrPrefsKeys.keyCooldown, jsonEncode(_keyCooldownUntil));
    await prefs.setString(
        OcrPrefsKeys.badKeys, jsonEncode(_badKeys.toList()));
  }

  Future<void> _persistActiveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OcrPrefsKeys.geminiActiveKey, _activeKeyIndex);
  }

  /// Key index i layak dipakai: ada, tidak bermasalah, tidak cooldown,
  /// dan model aktif tidak sedang diblokir kuota untuk key ini.
  bool _keyUsable(int i) {
    if (i < 0 || i >= _apiKeys.length || _badKeys.contains(i)) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final until = _keyCooldownUntil[i];
    if (until != null) {
      if (until > now) return false;
      _keyCooldownUntil.remove(i);
    }
    final quotaUntil = _quotaBlockedUntil['$i|$_modelId'];
    if (quotaUntil != null) {
      if (quotaUntil > now) return false;
      _quotaBlockedUntil.remove('$i|$_modelId');
    }
    return true;
  }

  /// Key layak berikutnya setelah `startAfter` (wrap), skip [tried].
  int? _nextUsableKey(int startAfter, Set<int> tried) {
    if (_apiKeys.isEmpty) return null;
    for (var step = 1; step <= _apiKeys.length; step++) {
      final i = (startAfter + step) % _apiKeys.length;
      if (tried.contains(i)) continue;
      if (_keyUsable(i)) return i;
    }
    return null;
  }

  void _useActiveKey() {
    if (_apiKeys.isEmpty) return;
    _activeKeyIndex = _activeKeyIndex.clamp(0, _apiKeys.length - 1);
    _geminiParser.initialize(_apiKeys[_activeKeyIndex], model: _modelId);
  }

  /// Initialize AI parser settings from SharedPreferences.
  /// Call this once when the provider is first created.
  Future<void> initializeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useAiParser = prefs.getBool(OcrPrefsKeys.useAiParser) ?? true;

      // Multi-key (baru); migrasi sekali dari single key lama.
      final stored = prefs.getString(OcrPrefsKeys.geminiApiKeys);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          _apiKeys = decoded.whereType<String>().toList();
        }
      } else {
        final legacy = prefs.getString(OcrPrefsKeys.geminiApiKey) ?? '';
        if (legacy.trim().isNotEmpty) {
          _apiKeys = [legacy.trim()];
          await prefs.setString(
              OcrPrefsKeys.geminiApiKeys, jsonEncode(_apiKeys));
          await prefs.remove(OcrPrefsKeys.geminiApiKey);
        }
      }
      _activeKeyIndex = prefs.getInt(OcrPrefsKeys.geminiActiveKey) ?? 0;
      _modelId = prefs.getString(OcrPrefsKeys.geminiModel) ??
          defaultGeminiModelId;
      if (geminiModelById(_modelId) == null) _modelId = defaultGeminiModelId;
      _hasApiKey = _apiKeys.isNotEmpty;

      // Quota map — prune yang kedaluwarsa.
      final quotaRaw = prefs.getString(OcrPrefsKeys.quotaBlocked);
      if (quotaRaw != null) {
        try {
          final decoded = jsonDecode(quotaRaw);
          if (decoded is Map) {
            final now = DateTime.now().millisecondsSinceEpoch;
            decoded.forEach((k, v) {
              if (k is String && v is int && v > now) {
                _quotaBlockedUntil[k] = v;
              }
            });
          }
        } catch (_) {}
      }

      // Kesehatan key: cooldown (gangguan) + key bermasalah (konfigurasi).
      final cooldownRaw = prefs.getString(OcrPrefsKeys.keyCooldown);
      if (cooldownRaw != null) {
        try {
          final decoded = jsonDecode(cooldownRaw);
          if (decoded is Map) {
            final now = DateTime.now().millisecondsSinceEpoch;
            decoded.forEach((k, v) {
              final idx = int.tryParse(k.toString());
              if (idx != null && v is int && v > now) {
                _keyCooldownUntil[idx] = v;
              }
            });
          }
        } catch (_) {}
      }
      final badRaw = prefs.getString(OcrPrefsKeys.badKeys);
      if (badRaw != null) {
        try {
          final decoded = jsonDecode(badRaw);
          if (decoded is List) {
            for (final v in decoded) {
              final idx = v is int ? v : int.tryParse('$v');
              if (idx != null) _badKeys.add(idx);
            }
          }
        } catch (_) {}
      }

      if (_hasApiKey) _useActiveKey();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load OCR settings: $e');
    }
  }

  /// Update the Gemini API key and persist it.
  /// Kompat lama: mengganti key aktif (index 0 bila belum ada).
  Future<void> setGeminiApiKey(String apiKey) async {
    final key = apiKey.trim();
    if (_apiKeys.isEmpty) {
      _apiKeys = [key];
      _activeKeyIndex = 0;
    } else {
      _activeKeyIndex = _activeKeyIndex.clamp(0, _apiKeys.length - 1);
      _apiKeys[_activeKeyIndex] = key;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OcrPrefsKeys.geminiApiKeys, jsonEncode(_apiKeys));
    _hasApiKey = key.isNotEmpty && _apiKeys.any((k) => k.isNotEmpty);

    if (_hasApiKey) _useActiveKey();
    notifyListeners();
  }

  /// Tambah API key baru (paste manual) dan jadikan aktif.
  Future<void> addApiKey(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) return;
    _apiKeys.add(key);
    _activeKeyIndex = _apiKeys.length - 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OcrPrefsKeys.geminiApiKeys, jsonEncode(_apiKeys));
    await prefs.setInt(OcrPrefsKeys.geminiActiveKey, _activeKeyIndex);
    _hasApiKey = true;
    _useActiveKey();
    notifyListeners();
  }

  /// Hapus key index i. Boleh hapus semua (→ regex saja). Bila yang aktif
  /// terhapus, aktif pindah ke index 0.
  Future<void> removeApiKey(int i) async {
    if (i < 0 || i >= _apiKeys.length) return;
    _apiKeys.removeAt(i);
    if (_apiKeys.isEmpty) {
      _activeKeyIndex = 0;
      _hasApiKey = false;
    } else {
      if (_activeKeyIndex >= _apiKeys.length) _activeKeyIndex = 0;
      _hasApiKey = true;
      _useActiveKey();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OcrPrefsKeys.geminiApiKeys, jsonEncode(_apiKeys));
    await prefs.setInt(OcrPrefsKeys.geminiActiveKey, _activeKeyIndex);
    notifyListeners();
  }

  /// Pilih key aktif.
  Future<void> setActiveKey(int i) async {
    if (i < 0 || i >= _apiKeys.length || i == _activeKeyIndex) return;
    _activeKeyIndex = i;
    await _persistActiveKey();
    _useActiveKey();
    notifyListeners();
  }

  /// Pilih model Gemini aktif.
  Future<void> setModel(String id) async {
    if (geminiModelById(id) == null || id == _modelId) return;
    _modelId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OcrPrefsKeys.geminiModel, id);
    if (_hasApiKey) _useActiveKey();
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
  /// Kompat: key aktif (migrasi dari single key lama sudah di load).
  Future<String> getGeminiApiKey() async {
    if (_apiKeys.isNotEmpty) {
      return _apiKeys[_activeKeyIndex.clamp(0, _apiKeys.length - 1)];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OcrPrefsKeys.geminiApiKey) ?? '';
  }

  /// Countdown ringkas sisa blokir kuota ("19j 34m" / "45m 10d" / "30d").
  /// Null bila model tidak diblokir. Tanpa DateFormat — murni aritmetik.
  String? quotaCountdownText(String model, {required bool isEn}) {
    final left = quotaRemaining(model);
    if (left == null) return null;
    final h = left.inHours;
    final m = left.inMinutes % 60;
    if (h > 0) {
      return isEn ? '${h}h ${m}m' : '${h}j ${m}m';
    }
    final s = left.inSeconds % 60;
    return isEn ? '${m}m ${s}s' : '${m}m ${s}d';
  }

  Future<void> pickAndScanReceipt(ImageSource source,
      {VoidCallback? onImageAcquired}) async {
    await pickImageAndScan(source: source, onImageAcquired: onImageAcquired);
  }

  Future<void> pickImageAndScan(
      {required ImageSource source, VoidCallback? onImageAcquired}) async {
    try {
      _resetScanStatusNote();
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
      // Gambar sudah didapat → pemanggil boleh menampilkan progress.
      // Batal pilih/izin ditolak tidak melewati titik ini (tidak ada popup).
      onImageAcquired?.call();
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
      // true bila jatuh ke regex KARENA kegagalan AI (kuota/gangguan/key)
      // → hasil wajib ditandai 'needs_review' (brief poin 3).
      var errorFallback = false;
      if (_useAiParser && _hasApiKey && await _isOnline()) {
        // Loop key: coba key aktif → gagal (klasifikasi) → pindah key
        // berikutnya sesuai urutan tersimpan → semua habis → regex.
        final tried = <int>{};
        var attempts = 0;
        var otherRetries = 0;
        while (true) {
          attempts++;
          // Pastikan key aktif layak; kalau tidak, geser ke key layak.
          if (!_keyUsable(_activeKeyIndex)) {
            final alt = _nextUsableKey(_activeKeyIndex, tried);
            if (alt == null) {
              _lastScanNotices.add(const ScanNotice(ScanNoticeKind.allFailed));
              errorFallback = true;
              debugPrint('🚫 Tidak ada API key layak → regex.');
              parsed = _regexParser.parse(rawText, imagePath: _capturedImage!.path);
              parsed = parsed.copyWith(parserSource: 'regex');
              break;
            }
            _activeKeyIndex = alt;
            await _persistActiveKey();
            _useActiveKey();
            notifyListeners();
          } else {
            _useActiveKey(); // sinkronkan model/key (setModel / ganti manual)
          }
          if (attempts > _apiKeys.length + 1) {
            // Pengaman loop: semua key sudah dicoba.
            _lastScanNotices.add(const ScanNotice(ScanNoticeKind.allFailed));
            errorFallback = true;
            parsed = _regexParser.parse(rawText, imagePath: _capturedImage!.path);
            parsed = parsed.copyWith(parserSource: 'regex');
            break;
          }
          try {
            debugPrint('🤖 Using Gemini AI parser (key ${_activeKeyIndex + 1}, $_modelId)...');
            parsed = await _geminiParser.parseOcrText(rawText, imagePath: _capturedImage!.path);
            debugPrint('✅ Gemini parser succeeded');
            break;
          } catch (e) {
            final failedKey = _activeKeyIndex;
            final kind = classifyGeminiError(e);
            debugPrint('⚠️ Gemini error (${kind.name}): $e');

            // Error 'lain' (timeout/jaringan) → 1x retry key yang sama
            // dulu sebelum menganggap key bermasalah.
            if (kind == GeminiErrorKind.other && otherRetries < 1) {
              otherRetries++;
              debugPrint('⏳ Gemini transient, retry...');
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            if (kind == GeminiErrorKind.quota) {
              final info = parseGeminiQuotaError(e, fallbackModel: _modelId);
              if (info != null) {
                _quotaBlockedUntil['$failedKey|${info.model}'] =
                    info.availableAt.millisecondsSinceEpoch;
                await _persistQuota();
                _lastScanNotices.add(ScanNotice(
                  ScanNoticeKind.quota,
                  model: info.model,
                  retry: info.retryAfter,
                ));
              } else {
                _lastScanNotices.add(const ScanNotice(ScanNoticeKind.quota));
              }
            } else if (kind == GeminiErrorKind.config) {
              // Key salah konfigurasi → tandai bermasalah permanen.
              _badKeys.add(failedKey);
              _lastScanNotices.add(ScanNotice(ScanNoticeKind.config,
                  fromKey: failedKey + 1));
            } else {
              // Gangguan server (5xx/overloaded) → cooldown key 2 menit.
              _keyCooldownUntil[failedKey] =
                  DateTime.now().millisecondsSinceEpoch + 120000;
              _lastScanNotices.add(const ScanNotice(ScanNoticeKind.overload));
            }
            await _persistKeyHealth();
            tried.add(failedKey);

            // Coba key berikutnya sesuai urutan tersimpan.
            final next = _nextUsableKey(failedKey, tried);
            if (next != null) {
              final reason = kind == GeminiErrorKind.config
                  ? 'config'
                  : kind == GeminiErrorKind.quota
                      ? 'limit'
                      : 'overload';
              scanStatusNote =
                  (from: failedKey + 1, to: next + 1, reason: reason);
              _lastScanNotices.add(ScanNotice(ScanNoticeKind.keySwitch,
                  fromKey: failedKey + 1, toKey: next + 1, reason: reason));
              _activeKeyIndex = next;
              await _persistActiveKey();
              _useActiveKey();
              notifyListeners(); // dialog menampilkan "Beralih ke key N…"
            }
            // Ulangi loop → key aktif sudah diganti (atau semua habis →
            // allFailed + regex di awal loop berikutnya).
          }
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
      // Brief: 'Valid' HANYA dari Gemini yang berhasil. Semua hasil offline
      // (error fallback, AI off, offline, tanpa key, model minta review)
      // → needs_review supaya chip "Perlu Review" tampil.
      final offlineResult = parsed.parserSource != 'gemini';
      if (errorFallback || parsed.reviewReason != null || offlineResult) {
        final base = _validationResult!;
        _validationResult = ValidationResult(
          status: 'needs_review',
          message: parsed.reviewReason ??
              (errorFallback
                  ? 'Fallback ke Offline Parser — hasil perlu direview user'
                  : 'Hasil Offline Parser — perlu dicek user'),
          expectedGrandTotal: base.expectedGrandTotal,
          actualGrandTotal: base.actualGrandTotal,
          difference: base.difference,
        );
        _parsedData = parsed.copyWith(validationStatus: 'needs_review');
      } else {
        _parsedData = parsed.copyWith(validationStatus: _validationResult!.status);
      }

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

      _resetScanStatusNote();
      _state = ScannerState.success;
      notifyListeners();
    } catch (e, stackTrace) {
      _resetScanStatusNote();
      if (_capturedImage == null) {
        // Gagal SEBELUM gambar ada (izin kamera/file bermasalah) →
        // kembali ke awal supaya bisa scan ulang tanpa sisa error.
        _state = ScannerState.idle;
        _errorMessage = '';
      } else {
        _state = ScannerState.error;
        _errorMessage = 'Gagal memproses struk: $e';
      }
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
