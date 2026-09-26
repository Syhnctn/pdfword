import { strToU8, zipSync } from "https://esm.sh/fflate@0.8.2";

const CONTENT_TYPES_XML =
  `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
  `<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">` +
  `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` +
  `<Default Extension="xml" ContentType="application/xml"/>` +
  `<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>` +
  `</Types>`;

const RELS_XML =
  `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
  `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
  `<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>` +
  `</Relationships>`;

function escapeXml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&apos;");
}

function buildDocumentXml(text: string) {
  const normalized = text.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
  const lines = normalized.length > 0 ? normalized.split("\n") : [""];
  const paragraphs = lines
    .map((line) => {
      const content = line.length > 0 ? escapeXml(line) : " ";
      return `<w:p><w:r><w:t xml:space="preserve">${content}</w:t></w:r></w:p>`;
    })
    .join("");

  return (
    `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
    `<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"` +
    ` xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"` +
    ` xmlns:o="urn:schemas-microsoft-com:office:office"` +
    ` xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"` +
    ` xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"` +
    ` xmlns:v="urn:schemas-microsoft-com:vml"` +
    ` xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"` +
    ` xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"` +
    ` xmlns:w10="urn:schemas-microsoft-com:office:word"` +
    ` xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"` +
    ` xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"` +
    ` xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"` +
    ` xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"` +
    ` xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"` +
    ` xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"` +
    ` mc:Ignorable="w14 wp14">` +
    `<w:body>${paragraphs}` +
    `<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/><w:cols w:space="708"/><w:docGrid w:linePitch="360"/></w:sectPr>` +
    `</w:body></w:document>`
  );
}

export function buildDocxFromText(text: string): Uint8Array {
  const docXml = buildDocumentXml(text);
  return zipSync({
    "[Content_Types].xml": strToU8(CONTENT_TYPES_XML),
    "_rels/.rels": strToU8(RELS_XML),
    "word/document.xml": strToU8(docXml),
  });
}
