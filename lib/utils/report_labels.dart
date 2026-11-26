/// Arabic labels and severity colors for image analysis results.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const unknownIssueClass = 'غير محدد';
const unknownSeverity = 'غير محددة';

String _key(Object? value) => value is String
    ? value
          .trim()
          .toLowerCase()
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .replaceAll(RegExp(r'[\s-]+'), '_')
    : '';

/// "تضرر سطح الرصيف", "مشكلة في منحدر الرصيف", or [unknownIssueClass].
String issueClassLabel(Object? value) => switch (_key(value)) {
  'surface_damage' => 'تضرر سطح الرصيف',
  'curb_ramp_issue' => 'مشكلة في منحدر الرصيف',
  _ => unknownIssueClass,
};

/// True for the high-severity values used by the analysis pipeline.
bool isSevere(Object? value) => const {'high', 'severe'}.contains(_key(value));

/// Model outputs with a medium component use the orange severity treatment.
bool isMediumSeverity(Object? value) => const {
  'medium',
  'low_medium',
  'low_medium_severity',
  'non_severe',
  'not_severe',
}.contains(_key(value));

/// Severity color: high is red, medium is orange, and low/unknown is neutral.
Color severityColor(Object? value) {
  if (isSevere(value)) return AppColors.error;
  if (isMediumSeverity(value)) return AppColors.amber;
  return const Color(0xFF6B7470);
}

/// "عالية", "متوسطة", "منخفضة", or the model's combined label.
String severityLabel(Object? value) {
  if (isSevere(value)) return 'عالية';
  return switch (_key(value)) {
    'medium' => 'متوسطة',
    'low' => 'منخفضة',
    'low_medium' ||
    'low_medium_severity' ||
    'non_severe' ||
    'not_severe' => 'منخفضة إلى متوسطة',
    _ => unknownSeverity,
  };
}
