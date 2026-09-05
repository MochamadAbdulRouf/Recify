import '../../data/models/parsed_receipt_data.dart';

/// Result of receipt validation with status and diagnostic details.
class ValidationResult {
  /// Status: 'valid', 'warning', or 'needs_review'
  final String status;

  /// Human-readable description of what was checked/found
  final String message;

  /// The computed expected grand total based on items + tax - discount
  final double expectedGrandTotal;

  /// The actual grand total from the receipt
  final double actualGrandTotal;

  /// The absolute difference between expected and actual
  final double difference;

  const ValidationResult({
    required this.status,
    required this.message,
    required this.expectedGrandTotal,
    required this.actualGrandTotal,
    required this.difference,
  });

  /// Quick check: is the receipt mathematically valid?
  bool get isValid => status == 'valid';

  /// Quick check: does the receipt need manual review?
  bool get needsReview => status == 'needs_review';
}

/// Validates receipt data by checking mathematical consistency
/// between items, tax, discount, and grand total.
class ReceiptValidator {
  /// Maximum allowed difference (in Rupiah) between calculated and actual grand total.
  /// Rp 500 tolerance accounts for kasir rounding, pembulatan, etc.
  static const double _toleranceValid = 500.0;

  /// Warning threshold: if difference is within this range, it's a warning
  /// but not necessarily wrong (e.g. service charge not captured, rounding).
  static const double _toleranceWarning = 5000.0;

  /// Validate the mathematical consistency of a parsed receipt.
  ///
  /// Checks: grandTotal ≈ sum(item prices) + tax - discount
  ///
  /// Returns a [ValidationResult] with status:
  /// - `'valid'`: grandTotal matches within ±Rp 500
  /// - `'warning'`: grandTotal is close but not exact (within ±Rp 5,000)
  /// - `'needs_review'`: grandTotal significantly differs from computed total
  static ValidationResult validate(ParsedReceiptData data) {
    // If no items and no grand total, nothing to validate
    if (data.items.isEmpty && data.grandTotal <= 0) {
      return const ValidationResult(
        status: 'warning',
        message: 'Tidak ada item atau total yang terdeteksi.',
        expectedGrandTotal: 0,
        actualGrandTotal: 0,
        difference: 0,
      );
    }

    // Calculate sum of all item prices
    final double calculatedItemsSum = data.items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    // Expected grand total: items + tax - discount
    final double expectedGrandTotal = calculatedItemsSum + data.tax - data.discount;

    // Absolute difference
    final double difference = (data.grandTotal - expectedGrandTotal).abs();

    // Determine status based on difference thresholds
    if (difference <= _toleranceValid) {
      return ValidationResult(
        status: 'valid',
        message: 'Total struk valid (selisih Rp ${difference.toStringAsFixed(0)}).',
        expectedGrandTotal: expectedGrandTotal,
        actualGrandTotal: data.grandTotal,
        difference: difference,
      );
    } else if (difference <= _toleranceWarning) {
      return ValidationResult(
        status: 'warning',
        message: 'Total struk mendekati perhitungan (selisih Rp ${difference.toStringAsFixed(0)}). '
            'Mungkin ada biaya tambahan atau pembulatan.',
        expectedGrandTotal: expectedGrandTotal,
        actualGrandTotal: data.grandTotal,
        difference: difference,
      );
    } else {
      return ValidationResult(
        status: 'needs_review',
        message: 'Total struk berbeda signifikan dari perhitungan item '
            '(selisih Rp ${difference.toStringAsFixed(0)}). Harap periksa kembali.',
        expectedGrandTotal: expectedGrandTotal,
        actualGrandTotal: data.grandTotal,
        difference: difference,
      );
    }
  }

  /// Quick boolean check: is the receipt mathematically valid?
  static bool isValid(ParsedReceiptData data) {
    return validate(data).isValid;
  }
}
