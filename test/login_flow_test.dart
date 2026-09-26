import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/app/app.dart';

void main() {
  testWidgets('auth action routes to convert screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PdfWordProApp()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_auth')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth_apple_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_convert')), findsOneWidget);
    expect(find.byKey(const Key('upload_zone')), findsOneWidget);
  });

  testWidgets('start converting button routes directly to convert screen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PdfWordProApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth_start_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_convert')), findsOneWidget);
  });
}
