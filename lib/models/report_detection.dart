import 'dart:ui' show Rect;

/// One issue detected in a report image by the analysis pipeline.
/// Stored in the report's `detections` array (Section 4.4.1).
class ReportDetection {
  const ReportDetection({
    required this.boxIndex,
    required this.issueClass,
    required this.severity,
    required this.confidence,
    required this.box,
  });

  final int boxIndex;

  /// surface_damage or curb_ramp_issue.
  final String issueClass;

  /// low_medium or high.
  final String severity;

  /// Detection confidence, 0 to 1.
  final double confidence;

  /// Position in the image, normalised to 0..1 (left, top, width, height).
  final Rect box;

  /// Reads the `detections` array; skips entries that are incomplete.
  static List<ReportDetection> listFrom(Object? value) {
    if (value is! List) return const [];
    final result = <ReportDetection>[];
    for (final item in value) {
      if (item is! Map) continue;
      final box = item['box'];
      final issueClass = item['issueClass'];
      final severity = item['severity'];
      final confidence = item['confidence'];
      if (box is! Map ||
          issueClass is! String ||
          severity is! String ||
          confidence is! num) {
        continue;
      }
      final x = box['x'], y = box['y'], w = box['w'], h = box['h'];
      if (x is! num || y is! num || w is! num || h is! num) continue;
      final index = item['boxIndex'];
      result.add(
        ReportDetection(
          boxIndex: index is int ? index : result.length,
          issueClass: issueClass,
          severity: severity,
          confidence: _unit(confidence),
          box: Rect.fromLTWH(
            _unit(x),
            _unit(y),
            _unit(w),
            _unit(h),
          ),
        ),
      );
    }
    result.sort((a, b) => a.boxIndex.compareTo(b.boxIndex));
    return result;
  }

  static double _unit(num value) =>
      value < 0 ? 0.0 : (value > 1 ? 1.0 : value.toDouble());
}
