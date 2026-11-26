import 'package:flutter/material.dart';

import '../theme/khota_colors.dart';
import 'report_explanation_icon.dart';

/// Display labels used by the report interface.
class ReportStatusLabels {
  static const analyzing = 'جارٍ تحليل الصورة';
  static const analysisCompleted = 'اكتمل تحليل الصورة';
  static const analysisFailed = 'تعذّر تحليل الصورة';

  static const pending = 'قيد الانتظار';
  static const inProgress = 'قيد التنفيذ من الجهة المختصة';
  static const resolved = 'تم الحل';

  static const all = 'الكل';
  static const filters = [all, pending, inProgress, resolved];

  /// Short chip text; the full status stays in the report details.
  static String short(String filter) =>
      filter == inProgress ? 'قيد التنفيذ' : filter;
}

/// Shows the citizen-facing report workflow status.
class ReportStatusSummary extends StatelessWidget {
  const ReportStatusSummary({super.key, required this.reportStatus});

  final String reportStatus;

  @override
  Widget build(BuildContext context) => _StatusItem(
    title: 'حالة البلاغ',
    value: reportStatus,
    icon: Icons.assignment_outlined,
    info: ReportInfoIcon.status(value: reportStatus),
  );
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.title,
    required this.value,
    required this.icon,
    this.info,
  });

  final String title;
  final String value;
  final IconData icon;
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.khota;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.mutedText, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: theme.textTheme.bodySmall)),
                ?info,
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter controls for report progress only: one row of chips the user
/// slides through, each with its number of reports.
class ReportStatusFilters extends StatelessWidget {
  const ReportStatusFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.counts = const {},
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  /// Number of reports per filter (filter label -> count).
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ReportStatusLabels.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReportStatusLabels.filters[index];
          final selected = selectedFilter == filter;
          final count = counts[filter];
          final fg = colors.text;
          return ChoiceChip(
            showCheckmark: false,
            selected: selected,
            onSelected: (_) => onFilterChanged(filter),
            backgroundColor: colors.surface,
            selectedColor: colors.surfaceSunken,
            shape: StadiumBorder(
              side: BorderSide(color: colors.outline, width: selected ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ReportStatusLabels.short(filter),
                  style: text.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      semanticsLabel: '$count بلاغ',
                      style: text.labelMedium?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
