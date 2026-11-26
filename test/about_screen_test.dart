import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/screens/info/about_screen.dart';
import 'package:khota_app/theme/app_theme.dart';

void main() {
  for (final size in [const Size(320, 740), const Size(800, 900)]) {
    testWidgets('About banner centers responsively at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('خُطى'), findsOneWidget);
      expect(find.text('أرصفة أفضل تبدأ بخطوة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
