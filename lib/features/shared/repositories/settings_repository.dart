import 'package:pdfword_pro/features/shared/models/settings_state.dart';

abstract class SettingsRepository {
  SettingsState seedSettings();

  SettingsState persist(SettingsState state);
}
