import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color backgroundStart = Color(0xFF050B1C);
  static const Color backgroundEnd = Color(0xFF081833);
  static const Color card = Color(0xFF111D36);
  static const Color cardBorder = Color(0xFF1E2C4A);
  static const Color primary = Color(0xFF2563FF);
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF8A97B3);
  static const Color success = Color(0xFF1ED9A1);
  static const Color danger = Color(0xFFFF5A6B);
  static const Color divider = Color(0xFF223356);
  static const Color input = Color(0xFF162441);
  static const Color glow = Color(0x992563FF);
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.card,
    required this.cardBorder,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
    required this.divider,
    required this.input,
    required this.glow,
    required this.navBackground,
    required this.infoBackground,
    required this.subtleBackground,
    required this.iconMuted,
    required this.iconBoxBackground,
    required this.iconBoxForeground,
  });

  final Color backgroundStart;
  final Color backgroundEnd;
  final Color card;
  final Color cardBorder;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color danger;
  final Color divider;
  final Color input;
  final Color glow;
  final Color navBackground;
  final Color infoBackground;
  final Color subtleBackground;
  final Color iconMuted;
  final Color iconBoxBackground;
  final Color iconBoxForeground;

  static const AppPalette dark = AppPalette(
    backgroundStart: Color(0xFF050B1C),
    backgroundEnd: Color(0xFF081833),
    card: Color(0xFF111D36),
    cardBorder: Color(0xFF1E2C4A),
    primary: AppColors.primary,
    textPrimary: Color(0xFFF4F7FF),
    textSecondary: Color(0xFF8A97B3),
    success: AppColors.success,
    danger: AppColors.danger,
    divider: Color(0xFF223356),
    input: Color(0xFF162441),
    glow: Color(0x992563FF),
    navBackground: Color(0xE50E1A32),
    infoBackground: Color(0xE6102142),
    subtleBackground: Color(0xE50C1730),
    iconMuted: Color(0xFF9DB1CF),
    iconBoxBackground: Color(0xFF162441),
    iconBoxForeground: Color(0xFF8FB6FF),
  );

  static const AppPalette light = AppPalette(
    backgroundStart: Color(0xFFF5F8FF),
    backgroundEnd: Color(0xFFE7F0FF),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFD5E2FA),
    primary: AppColors.primary,
    textPrimary: Color(0xFF14233C),
    textSecondary: Color(0xFF677891),
    success: AppColors.success,
    danger: AppColors.danger,
    divider: Color(0xFFD8E4F6),
    input: Color(0xFFF1F6FF),
    glow: Color(0x332563FF),
    navBackground: Color(0xF7FFFFFF),
    infoBackground: Color(0xFFF2F6FF),
    subtleBackground: Color(0xFFF3F7FF),
    iconMuted: Color(0xFF667A99),
    iconBoxBackground: Color(0xFFEAF1FF),
    iconBoxForeground: Color(0xFF2563FF),
  );

  @override
  AppPalette copyWith({
    Color? backgroundStart,
    Color? backgroundEnd,
    Color? card,
    Color? cardBorder,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
    Color? divider,
    Color? input,
    Color? glow,
    Color? navBackground,
    Color? infoBackground,
    Color? subtleBackground,
    Color? iconMuted,
    Color? iconBoxBackground,
    Color? iconBoxForeground,
  }) {
    return AppPalette(
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      divider: divider ?? this.divider,
      input: input ?? this.input,
      glow: glow ?? this.glow,
      navBackground: navBackground ?? this.navBackground,
      infoBackground: infoBackground ?? this.infoBackground,
      subtleBackground: subtleBackground ?? this.subtleBackground,
      iconMuted: iconMuted ?? this.iconMuted,
      iconBoxBackground: iconBoxBackground ?? this.iconBoxBackground,
      iconBoxForeground: iconBoxForeground ?? this.iconBoxForeground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      backgroundStart: Color.lerp(backgroundStart, other.backgroundStart, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      input: Color.lerp(input, other.input, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      subtleBackground: Color.lerp(
        subtleBackground,
        other.subtleBackground,
        t,
      )!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      iconBoxBackground: Color.lerp(
        iconBoxBackground,
        other.iconBoxBackground,
        t,
      )!,
      iconBoxForeground: Color.lerp(
        iconBoxForeground,
        other.iconBoxForeground,
        t,
      )!,
    );
  }
}

extension AppPaletteContextX on BuildContext {
  AppPalette get palette {
    return Theme.of(this).extension<AppPalette>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}
