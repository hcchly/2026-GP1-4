import 'package:flutter/material.dart';

import '../theme/khota_colors.dart';

class ReportStepIndicator extends StatelessWidget {
  const ReportStepIndicator({
    super.key,
    required this.title,
    required this.step,
    this.stepLabels = const ['الصورة', 'الموقع', 'المراجعة'],
  });

  final String title;
  final int step;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'خطوة $step من ${stepLabels.length}',
                  style: text.labelMedium?.copyWith(
                    color: context.khota.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label:
                  'الخطوة $step من ${stepLabels.length}: ${stepLabels[step - 1]}',
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 0; i < stepLabels.length; i++) ...[
                    Expanded(
                      child: _StepSegment(
                        number: i + 1,
                        label: stepLabels[i],
                        done: i + 1 < step,
                        current: i + 1 == step,
                      ),
                    ),
                    if (i + 1 < stepLabels.length) const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSegment extends StatelessWidget {
  const _StepSegment({
    required this.number,
    required this.label,
    required this.done,
    required this.current,
  });

  final int number;
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: current ? colors.primary : colors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (done)
            Icon(Icons.check_rounded, size: 16, color: colors.text)
          else
            Text(
              '$number',
              style: TextStyle(
                color: current ? colors.onPrimary : colors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: current ? colors.onPrimary : colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
