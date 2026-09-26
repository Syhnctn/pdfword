import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfword_pro/core/config/app_env.dart';
import 'package:pdfword_pro/features/convert/presentation/convert_controller.dart';
import 'package:pdfword_pro/features/shared/mock/mock_conversion_repository.dart';
import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/models/upload_state.dart';
import 'package:pdfword_pro/features/shared/real/supabase_ocr_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-page sample PDF (PyMuPDF) with a recognizable heading.
const String _samplePdfBase64 =
    'JVBERi0xLjcKJcK1wrYKCjEgMCBvYmoKPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDIgMCBSPj4KZW5kb2JqCgoyIDAgb2JqCjw8L1R5cGUvUGFnZXMvQ291bnQgMS9LaWRzWzQgMCBSXT4+CmVuZG9iagoKMyAwIG9iago8PC9Gb250PDwvaGVsdiA1IDAgUj4+Pj4KZW5kb2JqCgo0IDAgb2JqCjw8L1R5cGUvUGFnZS9NZWRpYUJveFswIDAgNTk1IDg0Ml0vUm90YXRlIDAvUmVzb3VyY2VzIDMgMCBSL1BhcmVudCAyIDAgUi9Db250ZW50c1s2IDAgUiA3IDAgUl0+PgplbmRvYmoKCjUgMCBvYmoKPDwvVHlwZS9Gb250L1N1YnR5cGUvVHlwZTEvQmFzZUZvbnQvSGVsdmV0aWNhL0VuY29kaW5nL1dpbkFuc2lFbmNvZGluZz4+CmVuZG9iagoKNiAwIG9iago8PC9MZW5ndGggOTMvRmlsdGVyL0ZsYXRlRGVjb2RlPj4Kc3RyZWFtCnjaFcgrDoVQDEVR31F0BvSe248hCBIMjqSOoPgEAQLD+N8jO8tseqhPKiz/Cgc4HJw3Ned+vQzlPHhu1XwL89VLqB8BiFqFGsTgFvK9UEhF/Xi35EhD0kQ//fwVLAplbmRzdHJlYW0KZW5kb2JqCgo3IDAgb2JqCjw8L0xlbmd0aCAxMDUvRmlsdGVyL0ZsYXRlRGVjb2RlPj4Kc3RyZWFtCnjaJYoxCoAwDEX3nCI3sI3tD4I4CC5uQjdx0hYHHVw8v5GSBP7Pe/TQmMizs/GsYiucbmrOfL3sLRde+9CiICsQVbRF9zdxAHYUVXGV2B92EcFYNSIOjWZ5DWaK5GFLM02JFvoApHAcPwplbmRzdHJlYW0KZW5kb2JqCgp4cmVmCjAgOAowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMTYgMDAwMDAgbiAKMDAwMDAwMDA2MiAwMDAwMCBuIAowMDAwMDAwMTE0IDAwMDAwIG4gCjAwMDAwMDAxNTUgMDAwMDAgbiAKMDAwMDAwMDI2OCAwMDAwMCBuIAowMDAwMDAwMzU3IDAwMDAwIG4gCjAwMDAwMDA1MTggMDAwMDAgbiAKCnRyYWlsZXIKPDwvU2l6ZSA4L1Jvb3QgMSAwIFIvSURbPEMyOTZDMzg4NzJDMzk5Nzg3QTUxNzZDM0EyQzJCQ0MyPjxBQjg5MzA1REZBNDExMTQ1NjI4NUMyMUMwQkIxNzNFNj5dPj4Kc3RhcnR4cmVmCjY5MgolJUVPRgo=';

Future<void> _waitUntil(
  bool Function() done, {
  Duration timeout = const Duration(minutes: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (done()) return;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw TimeoutException('Condition not met within $timeout');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('emulator: real signed-upload conversion flow produces a DOCX',
      (tester) async {
    expect(AppEnv.canUseSupabase, isTrue,
        reason: 'real backend config must be embedded in the build');

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
    final service = SupabaseOcrService(Supabase.instance.client);

    final controller = ConvertController(
      MockConversionRepository(),
      ocrService: service,
      deviceIdHashResolver: () async =>
          'itest-${DateTime.now().millisecondsSinceEpoch}',
    );

    final pdfBytes = Uint8List.fromList(base64Decode(_samplePdfBase64));
    controller.onAddPickedFiles([
      AppFileItem(
        id: 'f0',
        name: 'emulator_report.pdf',
        sizeMb: pdfBytes.lengthInBytes / 1048576,
        state: UploadState.queued,
        progress: 0,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      ),
    ]);

    await controller.onConvertTap();
    await _waitUntil(
      () => !controller.state.isConverting,
      timeout: const Duration(minutes: 5),
    );

    debugPrint('STATUS: ${controller.state.statusMessage}');
    expect(controller.state.recentConversions, isNotEmpty,
        reason: 'controller must record a conversion');

    final item = controller.state.recentConversions.first;
    debugPrint('JOB: ${item.id} -> ${item.name} (${item.status.name})');
    expect(item.status, ConversionJobStatus.succeeded);

    final signedUrl = await service.getSignedDownloadUrl(item.id);
    expect(signedUrl, isNotNull, reason: 'signed download url required');
    debugPrint('SIGNED URL OK');

    final httpClient = HttpClient();
    final response =
        await (await httpClient.getUrl(Uri.parse(signedUrl!))).close();
    expect(response.statusCode, 200);
    final docxBytes = await response.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    httpClient.close(force: true);
    debugPrint('DOCX bytes: ${docxBytes.length}');
    expect(docxBytes.length, greaterThan(1000));

    final archive = ZipDecoder().decodeBytes(docxBytes);
    final entry = archive.findFile('word/document.xml');
    expect(entry, isNotNull, reason: 'DOCX must contain word/document.xml');
    final xml = utf8.decode(entry!.content as List<int>);
    expect(xml.contains('Emulator E2E Report 2026'), isTrue,
        reason: 'converted DOCX must contain the PDF heading');
    debugPrint('DOCX contains expected heading: OK');
  });
}
