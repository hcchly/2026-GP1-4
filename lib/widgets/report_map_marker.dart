import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/khota_colors.dart';
import '../utils/report_labels.dart';
import 'report_status_widgets.dart';

/// Map marker colors. Color is used for severity only; the report status is
/// shown by the icon in a white corner badge.
class ReportMarkerColors {
  ReportMarkerColors._();

  static const high = AppColors.error;
  static const medium = AppColors.amber;
  static const neutral = Color(0xFF6B7470);

  /// Status badge: white with a dark icon, so it never competes with the
  /// severity color.
  static const badge = Colors.white;
  static const badgeIcon = Color(0xFF3A4440);
  static const badgeBorder = Color(0x33000000);

  static Color forSeverity(Object? severity) => severityColor(severity);
}

/// The three report statuses, each shown by its own icon.
enum MapReportStatus {
  pending(Icons.schedule_rounded, ReportStatusLabels.pending),
  inProgress(Icons.build_rounded, 'قيد التنفيذ'),
  resolved(Icons.check_rounded, ReportStatusLabels.resolved);

  const MapReportStatus(this.icon, this.label);

  final IconData icon;
  final String label;

  /// Reads the stored status value; unknown values have no badge.
  static MapReportStatus? from(Object? value) => switch (value) {
    'pending' || ReportStatusLabels.pending => pending,
    'in_progress' || ReportStatusLabels.inProgress => inProgress,
    'resolved' || ReportStatusLabels.resolved => resolved,
    _ => null,
  };
}

/// Small white round badge with the report status icon.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status, this.size = 18});

  final MapReportStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ReportMarkerColors.badge,
        shape: BoxShape.circle,
        border: Border.all(color: ReportMarkerColors.badgeBorder),
      ),
      child: Icon(
        status.icon,
        size: size * 0.62,
        color: ReportMarkerColors.badgeIcon,
      ),
    );
  }
}

/// Report marker: the fill color and icon show the severity, and the white
/// corner badge shows the report status. Resolved reports are drawn faded.
class ReportMapMarker extends StatelessWidget {
  const ReportMapMarker({
    super.key,
    required this.reportStatus,
    required this.severity,
    required this.onPressed,
    this.selected = false,
  });

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
    final status = MapReportStatus.from(reportStatus);

    return Semantics(
      selected: selected,
      label: [
        warning ? 'شدة ${severityLabel(severity)}' : 'لم تُحلَّل بعد',
        ?status?.label,
      ].join('، '),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.18 : 1,
        child: Opacity(
          opacity: status == MapReportStatus.resolved ? 0.55 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
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
              if (status != null)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: IgnorePointer(child: ReportStatusBadge(status: status)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map key in two groups: report status (the corner badge) and issue
/// severity (the marker itself).
class ReportMapLegend extends StatelessWidget {
  const ReportMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final text = theme.labelSmall;
    final heading = theme.labelMedium?.copyWith(fontWeight: FontWeight.w800);

    Widget row(Widget mark, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18, child: Center(child: mark)),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: text)),
        ],
      ),
    );

    Widget title(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(label, style: heading),
    );

    return Semantics(
      container: true,
      label: 'دليل علامات الخريطة',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('حالة البلاغ'),
              for (final status in MapReportStatus.values)
                row(ReportStatusBadge(status: status, size: 16), status.label),
              const Divider(height: 14),
              title('شدة المشكلة'),
              row(
                const Icon(
                  ReportMapMarker.severeIcon,
                  size: 17,
                  color: ReportMarkerColors.high,
                ),
                'عالية',
              ),
              row(
                const Icon(
                  ReportMapMarker.severeIcon,
                  size: 17,
                  color: ReportMarkerColors.medium,
                ),
                'منخفضة إلى متوسطة',
              ),
              row(
                const Icon(
                  ReportMapMarker.normalIcon,
                  size: 17,
                  color: ReportMarkerColors.neutral,
                ),
                'لم تُحلَّل بعد',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
