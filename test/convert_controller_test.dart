import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/features/convert/presentation/convert_controller.dart';
import 'package:pdfword_pro/features/shared/mock/mock_conversion_repository.dart';
import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/upload_state.dart';

void main() {
  test('onAddPickedFiles adds files to selected list', () {
    final controller = ConvertController(MockConversionRepository());
    final picked = [
      AppFileItem(
        id: 'f1',
        name: 'Contract.pdf',
        sizeMb: 1.2,
        state: UploadState.queued,
        progress: 0,
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      ),
    ];

    controller.onAddPickedFiles(picked);

    expect(controller.state.selectedFiles.length, 1);
    expect(controller.state.selectedFiles.first.name, 'Contract.pdf');
  });

  test('onRemoveFile removes selected file', () {
    final controller = ConvertController(MockConversionRepository());
    controller.onAddPickedFiles([
      AppFileItem(
        id: 'f1',
        name: 'Contract.pdf',
        sizeMb: 1.2,
        state: UploadState.queued,
        progress: 0,
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      ),
    ]);
    final firstId = controller.state.selectedFiles.first.id;

    controller.onRemoveFile(firstId);

    expect(controller.state.selectedFiles, isEmpty);
  });

  test('onConvertTap without backend falls back to mock conversion', () async {
    final controller = ConvertController(MockConversionRepository());
    controller.onAddPickedFiles([
      AppFileItem(
        id: 'f1',
        name: 'Contract.pdf',
        sizeMb: 1.2,
        state: UploadState.queued,
        progress: 0,
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      ),
    ]);

    await controller.onConvertTap();

    expect(controller.state.isConverting, isFalse);
    expect(controller.state.recentConversions, isNotEmpty);
    expect(controller.state.pendingPreview, isNull);
    expect(controller.state.statusMessage, contains('Mock conversion'));
  });
}
