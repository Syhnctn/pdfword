import 'package:flutter_test/flutter_test.dart';
import 'package:pdfword_pro/features/settings/presentation/settings_controller.dart';
import 'package:pdfword_pro/features/shared/mock/mock_settings_repository.dart';
import 'package:pdfword_pro/features/shared/models/settings_state.dart';

void main() {
  test('onToggleSetting updates dark mode flag', () {
    final repository = MockSettingsRepository();
    final controller = SettingsController(
      repository: repository,
      initialState: repository.seedSettings(),
      onLanguageChanged: (_) {},
    );

    controller.onToggleSetting(SettingToggle.darkMode, false);

    expect(controller.state.darkMode, isFalse);
  });

  test('onToggleSetting updates high quality flag', () {
    final repository = MockSettingsRepository();
    final controller = SettingsController(
      repository: repository,
      initialState: repository.seedSettings(),
      onLanguageChanged: (_) {},
    );

    controller.onToggleSetting(SettingToggle.highQualityConversion, true);

    expect(controller.state.highQualityConversion, isTrue);
  });

  test('onLanguageTap toggles language and invokes callback', () {
    final repository = MockSettingsRepository();
    AppLanguage? callbackValue;
    final controller = SettingsController(
      repository: repository,
      initialState: repository.seedSettings(),
      onLanguageChanged: (language) => callbackValue = language,
    );

    controller.onLanguageTap();

    expect(controller.state.language, AppLanguage.tr);
    expect(callbackValue, AppLanguage.tr);
  });
}
