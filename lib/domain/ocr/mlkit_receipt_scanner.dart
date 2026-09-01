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
    // 1. Collect all lines across all blocks
    final List<_ReceiptLineSegment> allSegments = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final rect = line.boundingBox;
        allSegments.add(_ReceiptLineSegment(
          text: text,
          left: rect.left.toDouble(),
          top: rect.top.toDouble(),
          right: rect.right.toDouble(),
          bottom: rect.bottom.toDouble(),
        ));
      }
    }

    if (allSegments.isEmpty) return recognizedText.text;

    // 2. Sort all segments strictly from top to bottom
    allSegments.sort((a, b) => a.top.compareTo(b.top));

    // 3. Cluster segments into visual horizontal rows
    final List<List<_ReceiptLineSegment>> rows = [];

    for (final segment in allSegments) {
      bool placed = false;
      for (final row in rows) {
        // Average centerY and height of existing segments in this row
        final rowCenterY = row.map((s) => s.centerY).reduce((a, b) => a + b) / row.length;
        final rowHeight = row.map((s) => s.height).reduce((a, b) => a + b) / row.length;

        // Tolerance: segments within 55% of average row height belong to the same visual line
        final tolerance = (rowHeight * 0.55).clamp(8.0, 40.0);
        if ((segment.centerY - rowCenterY).abs() < tolerance) {
          row.add(segment);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([segment]);
      }
    }

    // 4. Sort rows from top to bottom by their vertical center
    rows.sort((rowA, rowB) {
      final centerA = rowA.map((s) => s.centerY).reduce((a, b) => a + b) / rowA.length;
      final centerB = rowB.map((s) => s.centerY).reduce((a, b) => a + b) / rowB.length;
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
  final double height;

  _ReceiptLineSegment({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  })  : centerY = (top + bottom) / 2,
        height = (bottom - top).abs();
}
