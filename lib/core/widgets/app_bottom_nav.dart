import 'package:flutter/material.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';

enum AppTab { convert, history, settings }

extension AppTabX on AppTab {
  String get path {
    switch (this) {
      case AppTab.convert:
        return '/convert';
      case AppTab.history:
        return '/history';
      case AppTab.settings:
        return '/settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.convert:
        return Icons.compare_arrows_rounded;
      case AppTab.history:
        return Icons.history;
      case AppTab.settings:
        return Icons.settings_rounded;
    }
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case AppTab.convert:
        return l10n.text('convert');
      case AppTab.history:
        return l10n.text('history');
      case AppTab.settings:
        return l10n.text('settingsTab');
    }
  }

  String get testKey {
    switch (this) {
      case AppTab.convert:
        return 'bottom_nav_convert';
      case AppTab.history:
        return 'bottom_nav_history';
      case AppTab.settings:
        return 'bottom_nav_settings';
    }
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onChanged,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: palette.navBackground,
          border: Border.all(color: palette.cardBorder),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: AppTab.values.map((tab) {
            final active = tab == currentTab;
            return Expanded(
              child: Pressable(
                onTap: () => onChanged(tab),
                child: Container(
                  key: Key(tab.testKey),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        width: active ? 28 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Icon(
                        tab.icon,
                        size: 24,
                        color: active ? palette.primary : palette.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tab.label(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              active ? palette.primary : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
