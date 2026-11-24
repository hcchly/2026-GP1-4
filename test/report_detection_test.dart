import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/models/citizen_report.dart';
import 'package:khota_app/models/report_detection.dart';

void main() {
  test('reads the detections array written by the analysis function', () {
    final list = ReportDetection.listFrom([
      {
        'boxIndex': 1,
        'issueClass': 'curb_ramp_issue',
        'severity': 'high',
        'confidence': 0.42,
        'box': {'x': 0.15, 'y': 0.6, 'w': 0.1, 'h': 0.2},
      },
      {
        'boxIndex': 0,
        'issueClass': 'surface_damage',
        'severity': 'low_medium',
        'confidence': 0.81,
        'box': {'x': 0.4, 'y': 0.3, 'w': 0.2, 'h': 0.4},
      },
      {'issueClass': 'surface_damage'}, // incomplete: skipped
    ]);

    expect(list.length, 2);
    expect(list.first.boxIndex, 0);
    expect(list.first.issueClass, 'surface_damage');
    expect(list.first.box.left, closeTo(0.4, 1e-9));
    expect(list.last.severity, 'high');
  });

  test('missing or wrong detections give an empty list', () {
    expect(ReportDetection.listFrom(null), isEmpty);
    expect(ReportDetection.listFrom('x'), isEmpty);
  });

  test('CitizenReport.fromMap keeps the detections', () {
    final report = CitizenReport.fromMap('r1', {
      'description': 'test',
      'reportStatus': 'pending',
      'analysisStatus': 'completed',
      'issueClass': 'surface_damage',
      'severity': 'low_medium',
      'detections': [
        {
          'boxIndex': 0,
          'issueClass': 'surface_damage',
          'severity': 'low_medium',
          'confidence': 0.5,
          'box': {'x': 0, 'y': 0, 'w': 1, 'h': 1},
        },
      ],
    });
    expect(report.detections.length, 1);
  });
}
