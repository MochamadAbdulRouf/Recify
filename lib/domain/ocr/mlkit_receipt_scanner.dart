import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitReceiptScanner {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Process an image file and extract structured receipt text.
  /// Reconstructs lines by clustering TextLines by vertical (Y) position,
  /// preserving left-to-right reading order and merging separate column blocks
  /// (e.g. item name on the left, price on the right) onto the same physical line.
  Future<String> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isNotEmpty) {
        return _reconstructLayout(recognizedText);
      }

      return recognizedText.text;
    } catch (e) {
      throw Exception('Gagal melakukan ekstraksi teks OCR on-device: $e');
    }
  }

  /// Reconstruct receipt text using robust vertical line clustering.
  /// Works at the `TextLine` level (preserving intact words & numbers from ML Kit)
  /// rather than character or word tokens.
  String _reconstructLayout(RecognizedText recognizedText) {
    // 1. Collect all lines across all blocks with tilt/slope calculation
    final List<_ReceiptLineSegment> allSegments = [];
    final List<double> slopes = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final rect = line.boundingBox;

        double slope = 0.0;
        if (line.cornerPoints.length >= 2) {
          final p0 = line.cornerPoints[0];
          final p1 = line.cornerPoints[1];
          final dx = p1.x - p0.x;
          final dy = p1.y - p0.y;
          if (dx.abs() > 30) {
            final s = dy / dx;
            // Only consider reasonable slopes (tilt within ±25 degrees: tan(25°) ≈ 0.46)
            if (s.abs() < 0.46) {
              slope = s;
              slopes.add(s);
            }
          }
        }

        allSegments.add(_ReceiptLineSegment(
          text: text,
          left: rect.left.toDouble(),
          top: rect.top.toDouble(),
          right: rect.right.toDouble(),
          bottom: rect.bottom.toDouble(),
          slope: slope,
        ));
      }
    }

    if (allSegments.isEmpty) return recognizedText.text;

    // Compute median slope across all text lines to determine overall receipt tilt
    double medianSlope = 0.0;
    if (slopes.isNotEmpty) {
      slopes.sort();
      medianSlope = slopes[slopes.length ~/ 2];
    }

    // 2. Sort all segments strictly from top to bottom by tilt-adjusted vertical position
    allSegments.sort((a, b) => a.adjustedY(medianSlope).compareTo(b.adjustedY(medianSlope)));

    // 3. Cluster segments into visual horizontal rows using tilt-compensated coordinates
    final List<List<_ReceiptLineSegment>> rows = [];

    for (final segment in allSegments) {
      bool placed = false;
      for (final row in rows) {
        // Average adjustedY and height of existing segments in this row
        final rowAdjustedY = row.map((s) => s.adjustedY(medianSlope)).reduce((a, b) => a + b) / row.length;
        final rowHeight = row.map((s) => s.height).reduce((a, b) => a + b) / row.length;

        // Tolerance: segments within 65% of average row height belong to the same visual line
        // Increased clamp range to allow high-res camera photos (2400px) to cluster properly
        final tolerance = (rowHeight * 0.65).clamp(10.0, 60.0);
        if ((segment.adjustedY(medianSlope) - rowAdjustedY).abs() < tolerance) {
          row.add(segment);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([segment]);
      }
    }

    // 4. Sort rows from top to bottom by their tilt-adjusted vertical center
    rows.sort((rowA, rowB) {
      final centerA = rowA.map((s) => s.adjustedY(medianSlope)).reduce((a, b) => a + b) / rowA.length;
      final centerB = rowB.map((s) => s.adjustedY(medianSlope)).reduce((a, b) => a + b) / rowB.length;
      return centerA.compareTo(centerB);
    });

    // 5. Within each row, sort segments from left to right, then join with spacing
    final buffer = StringBuffer();
    for (final row in rows) {
      row.sort((a, b) => a.left.compareTo(b.left));

      // Build row text: if there is a gap between segments (e.g. name vs price), insert 4 spaces
      final rowBuffer = StringBuffer();
      for (int i = 0; i < row.length; i++) {
        if (i > 0) {
          final prev = row[i - 1];
          final curr = row[i];
          final gap = curr.left - prev.right;
          if (gap > 15) {
            rowBuffer.write('    '); // Multi-space column separator
          } else {
            rowBuffer.write(' ');
          }
        }
        rowBuffer.write(row[i].text);
      }

      final lineText = rowBuffer.toString().trim();
      if (lineText.isNotEmpty) {
        buffer.writeln(lineText);
      }
    }

    return buffer.toString();
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class _ReceiptLineSegment {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double centerY;
  final double centerX;
  final double height;
  final double slope;

  _ReceiptLineSegment({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.slope = 0.0,
  })  : centerY = (top + bottom) / 2,
        centerX = (left + right) / 2,
        height = (bottom - top).abs();

  /// Project the Y center to an imaginary vertical axis through X=0, removing tilt
  double adjustedY(double medianSlope) => centerY - (centerX * medianSlope);
}
