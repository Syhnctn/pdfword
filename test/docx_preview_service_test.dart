import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/core/files/docx_preview_service.dart';

Uint8List buildFakeDocx(String documentXml) {
  final xmlBytes = utf8.encode(documentXml);
  final archive = Archive()
    ..addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

void main() {
  final service = DocxPreviewService();

  test('parseDocumentXml maps styles, bullets and page breaks', () {
    const xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/'
        'wordprocessingml/2006/main"><w:body>'
        '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
        '<w:r><w:t>Quarterly Report</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>Intro &amp; overview</w:t></w:r></w:p>'
        '<w:p><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/>'
        '</w:numPr></w:pPr><w:r><w:t>Milestone one</w:t></w:r></w:p>'
        '<w:p><w:r><w:br w:type="page"/><w:t>Second page</w:t></w:r></w:p>'
        '</w:body></w:document>';

    final blocks = service.parseDocumentXml(xml);

    expect(blocks, hasLength(5));
    expect(blocks[0].type, PreviewBlockType.title);
    expect(blocks[0].text, 'Quarterly Report');
    expect(blocks[1].type, PreviewBlockType.paragraph);
    expect(blocks[1].text, 'Intro & overview');
    expect(blocks[2].type, PreviewBlockType.bullet);
    expect(blocks[2].text, 'Milestone one');
    expect(blocks[3].type, PreviewBlockType.pageBreak);
    expect(blocks[4].type, PreviewBlockType.paragraph);
    expect(blocks[4].text, 'Second page');
  });

  test('parseDocumentXml renders Heading2/Heading3 distinctly', () {
    const xml = '<w:document xmlns:w="x"><w:body>'
        '<w:p><w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
        '<w:r><w:t>Section</w:t></w:r></w:p>'
        '<w:p><w:pPr><w:pStyle w:val="Heading3"/></w:pPr>'
        '<w:r><w:t>Subsection</w:t></w:r></w:p>'
        '</w:body></w:document>';

    final blocks = service.parseDocumentXml(xml);

    expect(blocks, hasLength(2));
    expect(blocks[0].type, PreviewBlockType.heading);
    expect(blocks[1].type, PreviewBlockType.subheading);
  });

  test('parseDocxBytes reads word/document.xml from a zip container', () {
    const xml = '<w:document xmlns:w="x"><w:body>'
        '<w:p><w:r><w:t>From zip</w:t></w:r></w:p>'
        '</w:body></w:document>';

    final blocks = service.parseDocxBytes(buildFakeDocx(xml));

    expect(blocks, hasLength(1));
    expect(blocks.single.text, 'From zip');
  });

  test('parseDocxBytes returns empty list for invalid input', () {
    final blocks = service.parseDocxBytes(Uint8List.fromList([1, 2, 3]));
    expect(blocks, isEmpty);
  });
}