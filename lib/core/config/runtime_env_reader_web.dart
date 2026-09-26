// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? readRuntimeEnvImpl(String key) {
  final metaName = _metaNameByKey[key];
  if (metaName == null) return null;

  try {
    final node = html.document.querySelector('meta[name="$metaName"]');
    if (node is! html.MetaElement) return null;

    final value = node.content.trim();
    if (value.isEmpty) return null;
    return value;
  } catch (_) {
    return null;
  }
}

const Map<String, String> _metaNameByKey = {
  'USE_REAL_BACKEND': 'pdfword-use-real-backend',
  'SUPABASE_URL': 'pdfword-supabase-url',
  'SUPABASE_ANON_KEY': 'pdfword-supabase-anon-key',
  'OCR_WORKER_URL': 'pdfword-ocr-worker-url',
  'OCR_WORKER_SECRET': 'pdfword-ocr-worker-secret',
};
