import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:pdfword_pro/app/app.dart';

void main() {
  testGoldens('core auth screen golden', (tester) async {
    await loadAppFonts();
    await tester.pumpWidgetBuilder(
      const ProviderScope(child: PdfWordProApp()),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'auth_screen');
  }, skip: true);
}
