import 'package:flutter/material.dart';

import '../../models/citizen_report.dart';
import '../../models/report_detection.dart';
import '../../services/report_service.dart';
import '../../theme/khota_colors.dart';
import '../../utils/report_labels.dart';
import '../../widgets/detection_image.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/place_name.dart';
import '../../widgets/report_explanation_icon.dart';
import '../../widgets/private_report_image.dart';
import '../../widgets/report_status_widgets.dart';

/// Full details of one of the citizen's reports, opened from "بلاغاتي".
class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({
    super.key,
    required this.report,
    this.demo = false,
  });

  final CitizenReport report;

  /// True for the preview examples, which are not real reports.
  final bool demo;

  /// Same number as the submission confirmation and the list.
  static String displayNumber(String id) =>
      id.startsWith('DEMO-') ? id : ReportService.displayNumber(id);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;
    final analysisCompleted =
        report.analysisStatus == ReportStatusLabels.analysisCompleted;

    return Scaffold(
      appBar: const GradientAppBar(title: 'تفاصيل البلاغ'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  displayNumber(report.id),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: text.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.description,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (report.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColoredBox(
                      color: colors.surfaceSunken,
                      child: SizedBox(
                        width: double.infinity,
                        child: PrivateReportImage(
                          imageRef: report.imageUrl!,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                InfoCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ البلاغ',
                        child: Text(report.dateText),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'الموقع',
                        child: PlaceName(
                          address: report.address,
                          latitude: report.latitude,
                          longitude: report.longitude,
                          maxLines: 3,
                        ),
                      ),
                      if (analysisCompleted) ...[
                        const Divider(height: 1),
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'نوع المشكلة',
                          child: Text(issueClassLabel(report.issueClass)),
                        ),
                        const Divider(height: 1),
                        _DetailRow(
                          icon:
                              isSevere(report.severity) ||
                                  isMediumSeverity(report.severity)
                              ? Icons.warning_amber_rounded
                              : Icons.speed_outlined,
                          iconColor: severityColor(report.severity),
                          label: 'الشدة',
                          info: ReportInfoIcon.severity(value: report.severity),
                          child: Text(
                            severityLabel(report.severity),
                            style: TextStyle(
                              color: severityColor(report.severity),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (report.detections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetectionList(detections: report.detections),
                ],

                const SizedBox(height: 16),
                // Analysis continues in the backend; only citizen status is shown.
                ReportStatusSummary(reportStatus: report.reportStatus),

                if (demo) ...[
                  const SizedBox(height: 16),
                  const Text('هذا بلاغ تجريبي وليس بلاغًا حقيقيًا.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
    this.info,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? info;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodySmall?.copyWith(
                          color: colors.muted(0.65),
                        ),
                      ),
                    ),
                    ?info,
                  ],
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row per detected issue, numbered like the boxes on the image.
/// Shows each detected issue class once, with its original severity color.
class _DetectionList extends StatelessWidget {
  const _DetectionList({required this.detections});

  final List<ReportDetection> detections;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final uniqueIssues = <String, ReportDetection>{};
    for (final d in detections) {
      final existing = uniqueIssues[d.issueClass];
      if (existing == null ||
          (!isSevere(existing.severity) && isSevere(d.severity))) {
        uniqueIssues[d.issueClass] = d;
      }
    }

    final issues = uniqueIssues.entries.toList();

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              'المشكلات المكتشفة (${issues.length})',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final (i, entry) in issues.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: detectionColor(entry.value),
                    child: Icon(
                      isSevere(entry.value.severity) ||
                              isMediumSeverity(entry.value.severity)
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      issueClassLabel(entry.key),
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
