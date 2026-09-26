import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

const String _docxMimeType =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const String _docxUti = 'org.openxmlformats.wordprocessingml.document';

enum DocxOpenOutcome {
  opened,
  failed,
}

class DocxOpenResult {
  const DocxOpenResult._(this.outcome, {this.errorMessage});

  const DocxOpenResult.opened() : this._(DocxOpenOutcome.opened);

  const DocxOpenResult.failed([String? errorMessage])
      : this._(DocxOpenOutcome.failed, errorMessage: errorMessage);

  final DocxOpenOutcome outcome;
  final String? errorMessage;

  bool get isOpened => outcome == DocxOpenOutcome.opened;
}

abstract class DocxOpenService {
  Future<DocxOpenResult> openFromSignedUrl({
    required String signedUrl,
    required String suggestedFileName,
  });

  Future<DocxOpenResult> openFromAsset({
    required String assetPath,
    required String suggestedFileName,
  });

  Future<DocxOpenResult> openFromBytes({
    required Uint8List bytes,
    required String suggestedFileName,
  });
}

class ShareSheetDocxOpenService implements DocxOpenService {
  ShareSheetDocxOpenService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<DocxOpenResult> openFromSignedUrl({
    required String signedUrl,
    required String suggestedFileName,
  }) async {
    final uri = Uri.tryParse(signedUrl);
    if (uri == null) {
      return const DocxOpenResult.failed('invalid_signed_url');
    }

    final bytes = await _download(uri);
    if (bytes == null || bytes.isEmpty) {
      return const DocxOpenResult.failed('download_failed');
    }

    return _openDocxBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
    );
  }

  @override
  Future<DocxOpenResult> openFromAsset({
    required String assetPath,
    required String suggestedFileName,
  }) async {
    final bytes = await _loadAssetBytes(assetPath);
    if (bytes == null || bytes.isEmpty) {
      return const DocxOpenResult.failed('asset_load_failed');
    }

    return _openDocxBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
    );
  }

  @override
  Future<DocxOpenResult> openFromBytes({
    required Uint8List bytes,
    required String suggestedFileName,
  }) async {
    if (bytes.isEmpty) {
      return const DocxOpenResult.failed('empty_bytes');
    }
    return _openDocxBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
    );
  }

  Future<DocxOpenResult> _openDocxBytes({
    required Uint8List bytes,
    required String suggestedFileName,
  }) async {
    final file = await _writeDocxToTemp(
      _sanitizeDocxFileName(suggestedFileName),
      bytes,
    );
    if (file == null) {
      return const DocxOpenResult.failed('save_failed');
    }

    if (kIsWeb) {
      return _shareDocxFallback(file);
    }

    try {
      final result = await OpenFilex.open(
        file.path,
        type: _docxMimeType,
        uti: _docxUti,
      );

      switch (result.type) {
        case ResultType.done:
          return const DocxOpenResult.opened();
        case ResultType.noAppToOpen:
          final fallback = await _shareDocxFallback(file);
          return fallback.isOpened
              ? fallback
              : const DocxOpenResult.failed('no_app_to_open');
        case ResultType.fileNotFound:
          return const DocxOpenResult.failed('file_not_found');
        case ResultType.permissionDenied:
          return const DocxOpenResult.failed('permission_denied');
        case ResultType.error:
          final fallback = await _shareDocxFallback(file);
          return fallback.isOpened
              ? fallback
              : const DocxOpenResult.failed('open_file_failed');
      }
    } catch (_) {
      final fallback = await _shareDocxFallback(file);
      return fallback.isOpened
          ? fallback
          : const DocxOpenResult.failed('open_file_failed');
    }
  }

  Future<DocxOpenResult> _shareDocxFallback(File file) async {
    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: _docxMimeType)],
      );
      return const DocxOpenResult.opened();
    } catch (_) {
      return const DocxOpenResult.failed('share_sheet_failed');
    }
  }

  Future<Uint8List?> _download(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      return null;
    }
  }

  Future<File?> _writeDocxToTemp(String fileName, Uint8List bytes) async {
    try {
      final tempRoot = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}pdfword_pro_downloads',
      );
      if (!await tempRoot.exists()) {
        await tempRoot.create(recursive: true);
      }

      // Each call gets its own folder so the opened/shared file keeps its real
      // name (report.docx) instead of a timestamped file name.
      final runDir = Directory(
        '${tempRoot.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!await runDir.exists()) {
        await runDir.create(recursive: true);
      }

      final file = File('${runDir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  String _sanitizeDocxFileName(String fileName) {
    final trimmed = fileName.trim();
    final base = trimmed.isEmpty ? 'converted.docx' : trimmed;
    final withExt = base.toLowerCase().endsWith('.docx') ? base : '$base.docx';
    return withExt.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
