import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cv_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AntigravityCvApp(),
      ),
    );

    // Flush any pending zero-duration timers or init animation callbacks
    await tester.pump(const Duration(milliseconds: 50));

    // Verify that the widget tree mounts successfully.
    expect(find.byType(AntigravityCvApp), findsOneWidget);

    // Unmount the widget tree to dispose all animation controllers and tickers
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
