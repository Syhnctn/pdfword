import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/core/ads/convert_interstitial_ad_gate.dart';
import 'package:pdfword_pro/core/config/app_env.dart';
import 'package:pdfword_pro/core/device/device_id_service.dart';
import 'package:pdfword_pro/core/files/docx_open_service.dart';
import 'package:pdfword_pro/core/files/docx_preview_service.dart';
import 'package:pdfword_pro/features/auth/presentation/auth_controller.dart';
import 'package:pdfword_pro/features/convert/presentation/convert_controller.dart';
import 'package:pdfword_pro/features/history/presentation/history_controller.dart';
import 'package:pdfword_pro/features/settings/presentation/settings_controller.dart';
import 'package:pdfword_pro/features/shared/mock/mock_auth_gateway.dart';
import 'package:pdfword_pro/features/shared/mock/mock_conversion_repository.dart';
import 'package:pdfword_pro/features/shared/mock/mock_history_repository.dart';
import 'package:pdfword_pro/features/shared/mock/mock_settings_repository.dart';
import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/models/settings_state.dart';
import 'package:pdfword_pro/features/shared/real/real_auth_gateway.dart';
import 'package:pdfword_pro/features/shared/real/supabase_ocr_service.dart';
import 'package:pdfword_pro/features/shared/repositories/auth_gateway.dart';
import 'package:pdfword_pro/features/shared/repositories/conversion_repository.dart';
import 'package:pdfword_pro/features/shared/repositories/history_repository.dart';
import 'package:pdfword_pro/features/shared/repositories/settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Conversions completed in this app session (backend list reads may be
/// restricted by RLS, so the app keeps a local mirror for History/Recent).
final localConversionsProvider =
    StateProvider<List<ConversionHistoryItem>>((_) => const []);

final docxPreviewServiceProvider = Provider<DocxPreviewService>((_) {
  return DocxPreviewService();
});

final deviceIdServiceProvider = Provider<DeviceIdService>((_) {
  return DeviceIdService();
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppEnv.canUseSupabase) return null;
  try {
    return Supabase.instance.client;
  } catch (_) {
    // Providers may be read before Supabase.initialize (tests, early boot).
    return null;
  }
});

final ocrServiceProvider = Provider<SupabaseOcrService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseOcrService(client);
});

final docxOpenServiceProvider = Provider<DocxOpenService>((ref) {
  return ShareSheetDocxOpenService();
});

final convertInterstitialAdGateProvider =
    Provider<ConvertInterstitialAdGate>((ref) {
  final gate = ConvertInterstitialAdGate();
  gate.preload();
  ref.onDispose(gate.dispose);
  return gate;
});

final authGatewayProvider = Provider<AuthGateway>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RealAuthGateway(client);
  }
  return MockAuthGateway();
});

final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return MockConversionRepository();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthMockState>((ref) {
  return AuthController(ref.watch(authGatewayProvider));
});

final convertControllerProvider =
    StateNotifierProvider<ConvertController, ConvertViewState>((ref) {
  return ConvertController(
    ref.watch(conversionRepositoryProvider),
    ocrService: ref.watch(ocrServiceProvider),
    docxOpenService: ref.watch(docxOpenServiceProvider),
    deviceIdHashResolver: () => ref.read(deviceIdServiceProvider).getId(),
    onLocalConversion: (item) {
      final current = ref.read(localConversionsProvider);
      ref.read(localConversionsProvider.notifier).state = [
        item,
        ...current.where((existing) => existing.id != item.id),
      ].take(20).toList(growable: false);
    },
  );
});

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryViewState>((ref) {
  return HistoryController(
    ref.watch(historyRepositoryProvider),
    ocrService: ref.watch(ocrServiceProvider),
    docxOpenService: ref.watch(docxOpenServiceProvider),
  );
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final seeded = repository.seedSettings();
  return SettingsController(
    repository: repository,
    initialState: seeded,
    onLanguageChanged: (language) {
      ref.read(appLocaleProvider.notifier).state =
          language == AppLanguage.tr ? const Locale('tr') : const Locale('en');
    },
  );
});
