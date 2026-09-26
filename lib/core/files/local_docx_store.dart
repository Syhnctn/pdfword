import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Persists converted DOCX artifacts inside the app documents directory so
/// recent/history entries can be previewed or reopened without downloading.
class LocalDocxStore {
  Future<File> save(String id, Uint8List bytes) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}converted');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File('${dir.path}${Platform.pathSeparator}$safeId.docx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File?> find(String id) async {
    try {
      final root = await getApplicationDocumentsDirectory();
      final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final file = File(
        '${root.path}${Platform.pathSeparator}converted'
        '${Platform.pathSeparator}$safeId.docx',
      );
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }
}