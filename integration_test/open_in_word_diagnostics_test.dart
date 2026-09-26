// Manual device diagnostic for the "Open in Word" flow.
//
// Run on a device/emulator:
//   flutter test integration_test/open_in_word_diagnostics_test.dart -d <device>
//
// It exercises the real ShareSheetDocxOpenService, so on devices without a DOCX
// viewer the Android share sheet opens (the call is bounded by a timeout and a
// timeout is an expected outcome there). Not part of the host unit test set.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfword_pro/core/files/docx_open_service.dart';

const String _docxMime =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const String _docxUti = 'org.openxmlformats.wordprocessingml.document';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports how this device opens a converted DOCX', (tester) async {
    debugPrint('systemTemp: ${Directory.systemTemp.path}');

    final data = await rootBundle.load('assets/mock/converted_sample.docx');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    debugPrint('asset bytes: ${bytes.length}');

    // Raw plugin probe: does this device have a DOCX viewer at all?
    final probeDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}pdfword_pro_diag',
    );
    if (!await probeDir.exists()) {
      await probeDir.create(recursive: true);
    }
    final probeFile = File(
      '${probeDir.path}${Platform.pathSeparator}probe.docx',
    );
    await probeFile.writeAsBytes(bytes, flush: true);
    try {
      final raw = await OpenFilex.open(
        probeFile.path,
        type: _docxMime,
        uti: _docxUti,
      );
      debugPrint('OpenFilex raw: type=${raw.type} message=${raw.message}');
    } catch (e) {
      debugPrint('OpenFilex raw threw: $e');
    }

    final tempRoot = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}pdfword_pro_downloads',
    );
    final before = await _tempFiles(tempRoot);

    // Real service path used by the "Open in Word" button.
    final result = await ShareSheetDocxOpenService()
        .openFromBytes(bytes: bytes, suggestedFileName: 'emulator_report.docx')
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () =>
              const DocxOpenResult.failed('timeout_waiting_for_share_sheet'),
        );
    debugPrint('service outcome: ${result.outcome} err=${result.errorMessage}');

    final after = await _tempFiles(tempRoot);
    final created = after.difference(before);
    debugPrint('created temp files: $created');
    expect(
      created.where((path) => path.endsWith('emulator_report.docx')).length,
      1,
      reason: 'the temp DOCX must keep its suggested file name',
    );
  });
}

Future<Set<String>> _tempFiles(Directory root) async {
  if (!await root.exists()) return <String>{};
  final files = <String>{};
  await for (final entity in root.list(recursive: true)) {
    if (entity is File) {
      files.add(entity.path);
    }
  }
  return files;
}

