import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/core/files/docx_open_service.dart';
import 'package:pdfword_pro/core/files/docx_preview_service.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_screen.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

void main() {
  testWidgets('renders preview blocks and the open-in-word action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PreviewScreen(
            details: const PreviewDetails(
              jobId: 'job-1',
              fileName: 'Report.docx',
            ),
            loader: () async => PreviewLoadResult(
              blocks: const [
                PreviewBlock(PreviewBlockType.title, 'Quarterly Report'),
                PreviewBlock(PreviewBlockType.paragraph, 'Body paragraph'),
              ],
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_preview')), findsOneWidget);
    expect(find.text('Quarterly Report'), findsOneWidget);
    expect(find.text('Body paragraph'), findsOneWidget);
    expect(find.text('Open in Word'), findsOneWidget);
    expect(find.text('Report.docx'), findsOneWidget);
  });

  testWidgets('shows empty state when loader returns no blocks',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PreviewScreen(
            details: const PreviewDetails(
              jobId: 'job-2',
              fileName: 'Empty.docx',
            ),
            loader: () async => const PreviewLoadResult(blocks: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_preview')), findsOneWidget);
    expect(
      find.text('No previewable text was found in this document.'),
      findsOneWidget,
    );
  });

  testWidgets('open-in-word action works once the preview has loaded',
      (tester) async {
    final service = _RecordingOpenService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          docxOpenServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PreviewScreen(
            details: const PreviewDetails(
              jobId: 'job-3',
              fileName: 'Loaded.docx',
            ),
            loader: () async => PreviewLoadResult(
              blocks: const [
                PreviewBlock(PreviewBlockType.title, 'Loaded document'),
              ],
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open in Word'));
    await tester.pumpAndSettle();

    expect(
      service.openCalls,
      1,
      reason: 'tapping Open in Word must reach the open service',
    );
  });
}

class _RecordingOpenService implements DocxOpenService {
  int openCalls = 0;

  @override
  Future<DocxOpenResult> openFromAsset({
    required String assetPath,
    required String suggestedFileName,
  }) async {
    openCalls += 1;
    return const DocxOpenResult.opened();
  }

  @override
  Future<DocxOpenResult> openFromBytes({
    required Uint8List bytes,
    required String suggestedFileName,
  }) async {
    openCalls += 1;
    return const DocxOpenResult.opened();
  }

  @override
  Future<DocxOpenResult> openFromSignedUrl({
    required String signedUrl,
    required String suggestedFileName,
  }) async {
    openCalls += 1;
    return const DocxOpenResult.opened();
  }
}