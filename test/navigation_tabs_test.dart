import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/app/app.dart';

void main() {
  testWidgets('bottom tabs navigate between convert history and settings',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PdfWordProApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth_google_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_convert')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_history')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_settings')), findsOneWidget);
  });
}
