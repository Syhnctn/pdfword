import 'package:pdfword_pro/features/shared/models/settings_state.dart';
import 'package:pdfword_pro/features/shared/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  SettingsState _state = const SettingsState(
    profileName: 'Sarah Jenkins',
    email: 'sarah.j@example.com',
    isPro: false,
    darkMode: true,
    highQualityConversion: false,
    pushNotifications: true,
    emailUpdates: false,
    language: AppLanguage.en,
  );

  @override
  SettingsState persist(SettingsState state) {
    _state = state;
    return _state;
  }

  @override
  SettingsState seedSettings() => _state;
}
