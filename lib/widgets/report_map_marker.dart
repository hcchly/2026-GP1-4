import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/khota_colors.dart';
import '../utils/report_labels.dart';
import 'report_status_widgets.dart';

/// Map marker colors are driven by issue severity, never report workflow state.
class ReportMarkerColors {
  ReportMarkerColors._();

  static const high = AppColors.error;
  static const medium = AppColors.amber;
  static const neutral = Color(0xFF6B7470);

  static Color forSeverity(Object? severity) => severityColor(severity);
}

/// Report markers retain a neutral shape for low/unknown severity and show a
/// warning marker for the high and medium severity categories.
class ReportMapMarker extends StatelessWidget {
  const ReportMapMarker({
    super.key,
    required this.reportStatus,
    required this.severity,
    required this.onPressed,
    this.selected = false,
  });

  /// Retained for callers; workflow status does not affect marker styling.
  final Object? reportStatus;
  final Object? severity;
  final VoidCallback onPressed;
  final bool selected;

  static const normalIcon = Icons.location_on_rounded;
  static const severeIcon = Icons.warning_amber_rounded;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final warning = isSevere(severity) || isMediumSeverity(severity);

    return Semantics(
      selected: selected,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.18 : 1,
        child: IconButton(
          tooltip: 'عرض ملخص البلاغ',
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: ReportMarkerColors.forSeverity(severity),
            foregroundColor: Colors.white,
            side: BorderSide(
              color: colors.isDark ? Colors.white70 : Colors.white,
              width: 2,
            ),
          ),
          icon: Icon(warning ? severeIcon : normalIcon, size: 25),
        ),
      ),
    );
  }
}

/// Workflow labels stay in the key with neutral markers. Severity alone uses
/// red, orange, or neutral visual indicators.
class ReportMapLegend extends StatelessWidget {
  const ReportMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelSmall;

    Widget row(Widget mark, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16, child: Center(child: mark)),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: text)),
        ],
      ),
    );

    Widget dot(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Semantics(
      container: true,
      label: 'دليل ألوان الخريطة',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(dot(ReportMarkerColors.neutral), ReportStatusLabels.pending),
              row(
                dot(ReportMarkerColors.neutral),
                ReportStatusLabels.short(ReportStatusLabels.inProgress),
              ),
              row(dot(ReportMarkerColors.neutral), ReportStatusLabels.resolved),
              row(
                const Icon(
                  ReportMapMarker.severeIcon,
                  size: 16,
                  color: ReportMarkerColors.high,
                ),
                'شدة عالية',
              ),
              row(
                const Icon(
                  ReportMapMarker.severeIcon,
                  size: 16,
                  color: ReportMarkerColors.medium,
                ),
                'شدة متوسطة',
              ),
              row(dot(ReportMarkerColors.neutral), 'شدة منخفضة'),
            ],
          ),
        ),
      ),
    );
  }
}
