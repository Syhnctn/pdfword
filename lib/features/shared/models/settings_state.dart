enum AppLanguage {
  tr,
  en,
}

class SettingsState {
  const SettingsState({
    required this.profileName,
    required this.email,
    required this.isPro,
    required this.darkMode,
    required this.highQualityConversion,
    required this.pushNotifications,
    required this.emailUpdates,
    required this.language,
  });

  final String profileName;
  final String email;
  final bool isPro;
  final bool darkMode;
  final bool highQualityConversion;
  final bool pushNotifications;
  final bool emailUpdates;
  final AppLanguage language;

  SettingsState copyWith({
    String? profileName,
    String? email,
    bool? isPro,
    bool? darkMode,
    bool? highQualityConversion,
    bool? pushNotifications,
    bool? emailUpdates,
    AppLanguage? language,
  }) {
    return SettingsState(
      profileName: profileName ?? this.profileName,
      email: email ?? this.email,
      isPro: isPro ?? this.isPro,
      darkMode: darkMode ?? this.darkMode,
      highQualityConversion:
          highQualityConversion ?? this.highQualityConversion,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      language: language ?? this.language,
    );
  }
}
