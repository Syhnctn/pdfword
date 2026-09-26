import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/shared/real/supabase_ocr_service.dart';

enum PreviewBlockType {
  title,
  heading,
  subheading,
  bullet,
  paragraph,
  pageBreak,
}

@immutable
class PreviewBlock {
  const PreviewBlock(this.type, this.text);

  final PreviewBlockType type;
  final String text;
}

class PreviewLoadResult {
  const PreviewLoadResult({required this.blocks, this.bytes});

  final List<PreviewBlock> blocks;

  /// Raw DOCX bytes when available (used for "Open in Word").
  final Uint8List? bytes;

  bool get isEmpty => blocks.isEmpty;
}

/// Extracts readable preview content from converted DOCX files.
///
/// Rendering is intentionally lightweight: headings, bullets and paragraphs
/// are mapped from `word/document.xml` without a full Office renderer.
class DocxPreviewService {
  static const String mockAssetPath = 'assets/mock/converted_sample.docx';

  Future<PreviewLoadResult> load(
    PreviewDetails details, {
    SupabaseOcrService? ocrService,
  }) async {
    // 1) Locally saved artifact (direct conversion mode).
    final localPath = details.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      try {
        final file = File(localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final blocks = parseDocxBytes(bytes);
          if (blocks.isNotEmpty) {
            return PreviewLoadResult(blocks: blocks, bytes: bytes);
          }
        }
      } catch (_) {
        // Fall through to remote/asset sources.
      }
    }

    // 2) Signed URL from Supabase (standard backend mode).
    if (ocrService != null && !kIsWeb) {
      try {
        final url = await ocrService.getSignedDownloadUrl(details.jobId);
        if (url != null && url.isNotEmpty) {
          final bytes = await _download(Uri.parse(url));
          if (bytes != null) {
            final blocks = parseDocxBytes(bytes);
            if (blocks.isNotEmpty) {
              return PreviewLoadResult(blocks: blocks, bytes: bytes);
            }
          }
        }
      } catch (_) {
        // Fall through to the bundled sample.
      }
    }

    // 3) Bundled sample document so preview stays demo-able everywhere.
    try {
      final data = await rootBundle.load(mockAssetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final blocks = parseDocxBytes(bytes);
      return PreviewLoadResult(blocks: blocks, bytes: bytes);
    } catch (_) {
      return const PreviewLoadResult(blocks: []);
    }
  }

  List<PreviewBlock> parseDocxBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) return const [];
      final xml = utf8.decode(file.content, allowMalformed: true);
      return parseDocumentXml(xml);
    } catch (_) {
      return const [];
    }
  }

  List<PreviewBlock> parseDocumentXml(String xml) {
    final blocks = <PreviewBlock>[];
    final paragraphRe = RegExp(r'<w:p\b[^>]*>([\s\S]*?)</w:p>');
    final styleRe = RegExp(r'<w:pStyle[^>]*w:val="([^"]+)"');
    final textRe = RegExp(r'<w:t(?:\s[^>]*)?>([\s\S]*?)</w:t>');

    for (final match in paragraphRe.allMatches(xml)) {
      final inner = match.group(1) ?? '';

      final hasPageBreak = inner.contains('w:type="page"') ||
          inner.contains('lastRenderedPageBreak');
      if (hasPageBreak) {
        blocks.add(const PreviewBlock(PreviewBlockType.pageBreak, ''));
      }

      final style = styleRe.firstMatch(inner)?.group(1) ?? '';
      final isBullet = style.contains('List') || inner.contains('<w:numPr>');

      final buffer = StringBuffer();
      for (final textMatch in textRe.allMatches(inner)) {
        buffer.write(_unescapeXml(textMatch.group(1) ?? ''));
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) continue;

      blocks.add(PreviewBlock(_typeForStyle(style, isBullet), text));
    }

    return blocks;
  }

  PreviewBlockType _typeForStyle(String style, bool isBullet) {
    if (isBullet) return PreviewBlockType.bullet;
    switch (style) {
      case 'Title':
      case 'Heading1':
        return PreviewBlockType.title;
      case 'Heading2':
        return PreviewBlockType.heading;
      case 'Heading3':
      case 'Heading4':
      case 'Heading5':
        return PreviewBlockType.subheading;
      default:
        return PreviewBlockType.paragraph;
    }
  }

  String _unescapeXml(String value) {
    var out = value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
    out = out.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    out = out.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
    return out;
  }

  Future<Uint8List?> _download(Uri uri) async {
    if (kIsWeb) return null;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.getUrl(uri);
        final response = await request.close().timeout(
              const Duration(seconds: 60),
            );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }
}