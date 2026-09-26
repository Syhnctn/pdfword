import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/features/shared/models/settings_state.dart';
import 'package:pdfword_pro/features/shared/repositories/settings_repository.dart';

enum SettingToggle {
  darkMode,
  highQualityConversion,
  pushNotifications,
  emailUpdates,
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController({
    required SettingsRepository repository,
    required SettingsState initialState,
    required void Function(AppLanguage language) onLanguageChanged,
  })  : _repository = repository,
        _onLanguageChanged = onLanguageChanged,
        super(initialState);

  final SettingsRepository _repository;
  final void Function(AppLanguage language) _onLanguageChanged;

  void onToggleSetting(SettingToggle setting, bool value) {
    if (setting == SettingToggle.darkMode) {
      state = state.copyWith(darkMode: value);
    } else if (setting == SettingToggle.highQualityConversion) {
      state = state.copyWith(highQualityConversion: value);
    } else if (setting == SettingToggle.pushNotifications) {
      state = state.copyWith(pushNotifications: value);
    } else if (setting == SettingToggle.emailUpdates) {
      state = state.copyWith(emailUpdates: value);
    }
    _repository.persist(state);
  }

  void onLanguageTap() {
    final nextLanguage =
        state.language == AppLanguage.tr ? AppLanguage.en : AppLanguage.tr;
    state = state.copyWith(language: nextLanguage);
    _repository.persist(state);
    _onLanguageChanged(nextLanguage);
  }
}
