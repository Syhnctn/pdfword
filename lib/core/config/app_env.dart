import 'package:pdfword_pro/core/config/runtime_env_reader.dart';

class AppEnv {
  const AppEnv._();

  static const String _useRealBackendOverride = String.fromEnvironment(
    'USE_REAL_BACKEND',
    defaultValue: '',
  );

  // Built-in defaults (same project values as web/index.html) so native
  // builds talk to the real backend without extra dart-defines.
  static const String _defaultSupabaseUrl =
      'https://ujzovtnlqoxtutbaglas.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqem92dG5scW94dHV0YmFnbGFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNTM1ODYsImV4cCI6MjA4NjgyOTU4Nn0.'
      'rKCtQgNvl1VttIPRBKGEahvg9EvDfkA7dqcS0hiOsYI';

  static const String _supabaseUrlFromDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get useRealBackend {
    final fromRuntime = _parseBool(readRuntimeEnv('USE_REAL_BACKEND'));
    if (fromRuntime != null) return fromRuntime;
    final fromDefine = _parseBool(_useRealBackendOverride);
    if (fromDefine != null) return fromDefine;

    // If credentials are present via runtime/define/default, enable backend mode.
    return supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
  }

  static String get supabaseUrl {
    return _firstNonEmpty(
      _supabaseUrlFromDefine,
      readRuntimeEnv('SUPABASE_URL'),
      _defaultSupabaseUrl,
    );
  }

  static String get supabaseAnonKey {
    return _firstNonEmpty(
      _supabaseAnonKeyFromDefine,
      readRuntimeEnv('SUPABASE_ANON_KEY'),
      _defaultSupabaseAnonKey,
    );
  }

  // Built-in production OCR worker (Render) so any build — including release
  // AAB/APKs installed on physical devices — can convert without extra
  // dart-defines. Without this, Android builds silently fall back to the
  // emulator-only loopback address below and conversion fails on real phones.
  static const String _defaultOcrWorkerUrl =
      'https://pdfword-ocr-worker.onrender.com';

  // The worker bearer secret is intentionally NOT committed.
  //
  // Supply it at build time instead:
  //   flutter build appbundle --dart-define=OCR_WORKER_SECRET=<secret>
  // or drop it in `web/index.html` for web builds. If it is missing, direct
  // worker calls are skipped and the app falls back to the hosted Supabase
  // edge functions, which keep working.
  static const String _defaultOcrWorkerSecret = '';

  /// Base URL of the OCR worker used for direct (bytes) conversion.
  ///
  /// Defaults to the hosted production worker. For local development against
  /// a worker running on the dev machine, pass
  /// `--dart-define=OCR_WORKER_URL=http://10.0.2.2:8080` (Android emulator
  /// loopback) or `http://127.0.0.1:8080` (web/desktop).
  static String get ocrWorkerUrl {
    const fromDefine = String.fromEnvironment(
      'OCR_WORKER_URL',
      defaultValue: '',
    );
    final trimmed = fromDefine.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.replaceAll(RegExp(r'/+$'), '');
    }
    return _defaultOcrWorkerUrl;
  }

  /// Optional bearer secret for the OCR worker's internal endpoints.
  static String get ocrWorkerSecret {
    const fromDefine = String.fromEnvironment(
      'OCR_WORKER_SECRET',
      defaultValue: '',
    );
    final trimmed = fromDefine.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return _defaultOcrWorkerSecret;
  }

  static bool get canUseSupabase {
    return useRealBackend &&
        supabaseUrl.trim().isNotEmpty &&
        supabaseAnonKey.trim().isNotEmpty;
  }

  static List<String> get missingSupabaseConfig {
    final missing = <String>[];
    if (supabaseUrl.trim().isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.trim().isEmpty) missing.add('SUPABASE_ANON_KEY');
    return missing;
  }

  static bool? _parseBool(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
  }

  static String _firstNonEmpty(String first, String? second, [String third = '']) {
    if (first.trim().isNotEmpty) return first;
    if (second != null && second.trim().isNotEmpty) return second;
    return third;
  }
}
