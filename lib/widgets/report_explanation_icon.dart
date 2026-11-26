import 'package:flutter/material.dart';

/// Opens a short citizen-facing explanation for a report status or severity.
/// The icon remains visible while the explanation is shown only after a tap.
class ReportInfoIcon extends StatelessWidget {
  const ReportInfoIcon.status({super.key, required this.value})
    : _kind = _ReportExplanationKind.status;

  const ReportInfoIcon.severity({super.key, required this.value})
    : _kind = _ReportExplanationKind.severity;

  final Object? value;
  final _ReportExplanationKind _kind;

  _ReportExplanation? get _explanation {
    final rawValue = value;
    final key = rawValue is String
        ? rawValue.trim().toLowerCase().replaceAll('-', '_')
        : '';
    if (_kind == _ReportExplanationKind.status) {
      return switch (key) {
        'pending' || 'قيد الانتظار' => const _ReportExplanation(
          title: 'حالة البلاغ: قيد الانتظار',
          description: 'تم استلام بلاغك، وهو بانتظار المراجعة أو المعالجة.',
        ),
        'in_progress' ||
        'in progress' ||
        'inprogress' ||
        'قيد التنفيذ' ||
        'قيد التنفيذ من الجهة المختصة' => const _ReportExplanation(
          title: 'حالة البلاغ: قيد التنفيذ',
          description: 'تم الاطلاع على المشكلة، والعمل على معالجتها جارٍ.',
        ),
        'resolved' ||
        'completed' ||
        'done' ||
        'تم الحل' => const _ReportExplanation(
          title: 'حالة البلاغ: تم الحل',
          description: 'تمت معالجة المشكلة ووُضعت حالة البلاغ على أنها محلولة.',
        ),
        _ => null,
      };
    }

    return switch (key) {
      'low' => const _ReportExplanation(
        title: 'مستوى الشدة: منخفضة',
        description:
            'مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.',
      ),
      'medium' => const _ReportExplanation(
        title: 'مستوى الشدة: متوسطة',
        description: 'مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      ),
      'high' || 'severe' => const _ReportExplanation(
        title: 'مستوى الشدة: عالية',
        description: 'مشكلة خطيرة قد تشكل خطرًا كبيرًا على سلامة المشاة أو سهولة وصولهم وتتطلب اهتمامًا أكبر.',
      ),
      'low_medium' || 'non_severe' || 'not_severe' => const _ReportExplanation(
        title: 'مستوى الشدة: منخفضة إلى متوسطة',
        description: 'منخفضة: مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.\n\nمتوسطة: مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      ),
      'عالية' => const _ReportExplanation(
        title: 'مستوى الشدة: عالية',
        description: 'مشكلة خطيرة قد تشكل خطرًا كبيرًا على سلامة المشاة أو سهولة وصولهم وتتطلب اهتمامًا أكبر.',
      ),
      'منخفضة' => const _ReportExplanation(
        title: 'مستوى الشدة: منخفضة',
        description:
            'مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.',
      ),
      'متوسطة' => const _ReportExplanation(
        title: 'مستوى الشدة: متوسطة',
        description: 'مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      ),
      'منخفضة إلى متوسطة' => const _ReportExplanation(
        title: 'مستوى الشدة: منخفضة إلى متوسطة',
        description: 'منخفضة: مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.\n\nمتوسطة: مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final explanation = _explanation;
    if (explanation == null) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'معلومات عن ${explanation.title}',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      iconSize: 18,
      color: Theme.of(context).colorScheme.primary,
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  explanation.title,
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  explanation.description,
                  style: Theme.of(sheetContext).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportExplanation {
  const _ReportExplanation({required this.title, required this.description});

  final String title;
  final String description;
}

enum _ReportExplanationKind { status, severity }
