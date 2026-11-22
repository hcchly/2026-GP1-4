import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/citizen_report.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/place_name.dart';
import '../../widgets/report_status_widgets.dart';
import 'report_details_screen.dart';

export '../../models/citizen_report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.initialPreview = false, this.reports});

  final bool initialPreview;

  /// Overrides the signed-in citizen's reports from Firestore (tests).
  final Stream<List<CitizenReport>>? reports;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = 'الكل';

  late bool previewMode = widget.initialPreview;

  /// Created once, so changing the filter does not restart the listener.
  late Stream<List<CitizenReport>>? _liveReports =
      widget.reports ?? ReportService.watchOwnReports();

  void _retryReports() {
    setState(
      () => _liveReports = widget.reports ?? ReportService.watchOwnReports(),
    );
  }

  // Demo reports are for UI preview only.
  // They are not real citizen reports.
  static final sampleReports = <CitizenReport>[
    CitizenReport(
      id: 'DEMO-01',
      description: 'بلاط رصيف مكسور',
      reportStatus: ReportStatusLabels.pending,
      analysisStatus: ReportStatusLabels.analyzing,
      createdAt: DateTime(2026, 11, 12),
      address: 'حي العليا، طريق الملك فهد',
    ),
    CitizenReport(
      id: 'DEMO-02',
      description: 'منحدر رصيف يحتاج إلى صيانة',
      reportStatus: ReportStatusLabels.inProgress,
      analysisStatus: 'اكتمل تحليل الصورة',
      createdAt: DateTime(2026, 11, 5),
      address: 'حي النرجس، شارع أنس بن مالك',
      issueClass: 'curb_ramp_issue',
      severity: 'non_severe',
    ),
    CitizenReport(
      id: 'DEMO-03',
      description: 'رصيف مائل قرب ممر مشاة',
      reportStatus: ReportStatusLabels.resolved,
      analysisStatus: 'اكتمل تحليل الصورة',
      createdAt: DateTime(2026, 10, 20),
      address: 'حي الملقا، طريق الأمير محمد بن سعد',
      issueClass: 'surface_damage',
      severity: 'severe',
    ),
  ];

  // Display the same report number used after submission.
  String displayReportNumber(String id) =>
      ReportDetailsScreen.displayNumber(id);

  // Open report details on a separate page.
  void openDetails(CitizenReport report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailsScreen(report: report, demo: previewMode),
      ),
    );
  }

  // Activate preview mode.
  Widget previewButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          previewMode = true;
          selectedFilter = 'الكل';
        });
      },
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('معاينة الحالات والفلاتر'),
    );
  }

  // Build reports according to selected filter, newest first.
  Widget buildReportList(List<CitizenReport> unsorted) {
    final reports = [...unsorted]..sort(CitizenReport.newestFirst);

    final filtered = selectedFilter == ReportStatusLabels.all
        ? reports
        : reports
              .where((report) => report.reportStatus == selectedFilter)
              .toList();

    final counts = {
      for (final filter in ReportStatusLabels.filters)
        filter: filter == ReportStatusLabels.all
            ? reports.length
            : reports.where((r) => r.reportStatus == filter).length,
    };

    // Four filters in one sliding row: All, Pending, In Progress, Resolved.
    final filters = reports.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ReportStatusFilters(
              selectedFilter: selectedFilter,
              counts: counts,
              onFilterChanged: (value) =>
                  setState(() => selectedFilter = value),
            ),
          );

    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [filters, _emptyState(reports)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'الأحدث أولًا',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: context.khota.muted(0.7)),
          ),
        ),
        _reportCards(filtered),
      ],
    );
  }

  Widget _emptyState(List<CitizenReport> reports) {
    return InfoCard(
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: context.khota.primary),

          const SizedBox(height: 12),

          Text(
            reports.isEmpty
                ? 'لا توجد بلاغات بعد'
                : 'لا توجد بلاغات بهذه الحالة',
          ),

          const SizedBox(height: 8),
          Text(
            reports.isEmpty
                ? 'اضغط «بلاغ جديد» أسفل الشاشة لإرسال أول بلاغ.'
                : 'اختَر حالة أخرى أو اعرض كل البلاغات.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.khota.muted(0.7)),
          ),
          if (reports.isNotEmpty)
            TextButton(
              onPressed: () =>
                  setState(() => selectedFilter = ReportStatusLabels.all),
              child: const Text('عرض كل البلاغات'),
            ),

          if (reports.isEmpty && !previewMode) ...[
            const SizedBox(height: 12),
            if (kDebugMode) previewButton(),
          ],
        ],
      ),
    );
  }

  Widget _reportCards(List<CitizenReport> filtered) {
    final text = Theme.of(context).textTheme;
    final muted = context.khota.muted(0.6);

    return Column(
      children: [
        for (final report in filtered) ...[
          InkWell(
            key: ValueKey(report.id),
            onTap: () => openDetails(report),
            borderRadius: BorderRadius.circular(20),
            child: InfoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const IconTile(icon: Icons.assignment_outlined, size: 38),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'بلاغ ${displayReportNumber(report.id)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Icon(
                        Icons.chevron_left_rounded,
                        color: context.khota.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    report.description,
                    style: text.bodyMedium?.copyWith(
                      color: context.khota.muted(0.76),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Place name and date, as on the home cards.
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: PlaceName(
                          address: report.address,
                          latitude: report.latitude,
                          longitude: report.longitude,
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.dateText,
                          style: text.labelSmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ReportStatusSummary(
                    analysisStatus: report.analysisStatus,
                    reportStatus: report.reportStatus,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'عرض التفاصيل',
                          style: text.labelLarge?.copyWith(
                            color: context.khota.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: context.khota.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget buildLiveReports() {
    final reports = _liveReports;

    if (reports == null) {
      return InfoCard(
        child: Column(
          children: [
            const Text('سجّل الدخول لعرض بلاغاتك.'),

            const SizedBox(height: 12),

            if (kDebugMode) previewButton(),
          ],
        ),
      );
    }

    return StreamBuilder<List<CitizenReport>>(
      stream: reports,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InfoCard(
            child: Column(
              children: [
                const Text(
                  'تعذّر تحميل البلاغات. تحقق من اتصال الإنترنت ثم حاول مجددًا.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: _retryReports,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return buildReportList(snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'بلاغاتي', compact: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
          children: [
            if (previewMode) ...[
              InfoCard(
                color: AppColors.tealLight.withValues(alpha: 0.18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'وضع المعاينة: هذه أمثلة تجريبية وليست بلاغات حقيقية.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          previewMode = false;
                          selectedFilter = 'الكل';
                        });
                      },
                      child: const Text('العودة إلى بلاغاتي الحقيقية'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              buildReportList(sampleReports),
            ] else
              buildLiveReports(),
          ],
        ),
      ),
    );
  }
}
