import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/widgets/report_explanation_icon.dart';

void main() {
  Future<void> expectExplanation(
    WidgetTester tester, {
    required Widget icon,
    required String explanation,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: icon)),
      ),
    );

    expect(find.text(explanation), findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text(explanation), findsOneWidget);
    expect(find.text('إغلاق'), findsOneWidget);
  }

  group('report status explanations', () {
    testWidgets('Pending opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.status(value: 'pending'),
        explanation: 'تم استلام بلاغك، وهو بانتظار المراجعة أو المعالجة.',
      );
    });

    testWidgets('In Progress opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.status(value: 'in_progress'),
        explanation: 'تم الاطلاع على المشكلة، والعمل على معالجتها جارٍ.',
      );
    });

    testWidgets('Resolved opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.status(value: 'resolved'),
        explanation: 'تمت معالجة المشكلة ووُضعت حالة البلاغ على أنها محلولة.',
      );
    });
  });

  group('severity explanations', () {
    testWidgets('Low opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.severity(value: 'low'),
        explanation:
            'مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.',
      );
    });

    testWidgets('Medium opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.severity(value: 'medium'),
        explanation: 'مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      );
    });

    testWidgets('High opens its Arabic explanation', (tester) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.severity(value: 'high'),
        explanation: 'مشكلة خطيرة قد تشكل خطرًا كبيرًا على سلامة المشاة أو سهولة وصولهم وتتطلب اهتمامًا أكبر.',
      );
    });

    testWidgets('model non-severe result explains Low and Medium', (
      tester,
    ) async {
      await expectExplanation(
        tester,
        icon: const ReportInfoIcon.severity(value: 'non_severe'),
        explanation:
            'منخفضة: مشكلة بسيطة ذات أثر محدود على سلامة المشاة أو سهولة وصولهم.\n\n'
            'متوسطة: مشكلة ملحوظة قد تسبب إزعاجًا للمشاة أو تثير قلقًا بشأن السلامة أو سهولة الوصول.',
      );
    });
  });
}
