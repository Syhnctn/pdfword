import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/app/router.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';
import 'package:pdfword_pro/features/settings/presentation/settings_controller.dart';
import 'package:pdfword_pro/features/shared/models/settings_state.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routePath = AppRoutes.settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final palette = context.palette;
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.height < 760;
    final isNarrow = media.width < 390;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      child: Column(
        key: const Key('screen_settings'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('settings'),
            style: TextStyle(
              fontSize: isCompact ? 34 : 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: palette.divider),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: isCompact ? 84 : 96,
                        height: isCompact ? 84 : 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset('assets/icons/avatar.svg'),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Pressable(
                          onTap: () => _showSnack(
                            context,
                            'Profil duzenleme ekrani yakinda.',
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.card,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.profileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 19 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Pressable(
                    onTap: () => _showPremiumDialog(
                      context,
                      title: l10n.text('comingSoon'),
                      message:
                          'Premium ozellikler yakinda. Simdilik reklamli ucretsiz mod aktif.',
                    ),
                    child: Container(
                      height: isCompact ? 44 : 48,
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 16 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.text('comingSoon'),
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(title: l10n.text('account')),
          _SettingsCard(
            children: [
              _StaticRow(
                icon: Icons.credit_card_rounded,
                title: l10n.text('subscription'),
                trailingText: l10n.text('freePlan'),
                tagText: state.isPro ? 'PRO' : l10n.text('comingSoon'),
                onTap: () => _showPremiumDialog(
                  context,
                  title: l10n.text('subscription'),
                  message: state.isPro
                      ? 'Pro plan aktif.'
                      : 'Abonelik ekrani yakinda. Ucretsiz plan ile devam ediliyor.',
                ),
              ),
              const _DividerLine(),
              _StaticRow(
                icon: Icons.restore,
                title: l10n.text('restorePurchases'),
                tagText: l10n.text('comingSoon'),
                onTap: () => _showPremiumDialog(
                  context,
                  title: l10n.text('restorePurchases'),
                  message:
                      'Satin alim geri yukleme sadece premium/yayin ortami icin aktif olur.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: l10n.text('preferences')),
          _SettingsCard(
            children: [
              _StaticRow(
                icon: Icons.language_rounded,
                title: l10n.text('language'),
                trailingText:
                    state.language == AppLanguage.tr ? 'Turkce' : 'English',
                onTap: () {
                  controller.onLanguageTap();
                  _showSnack(context, 'Dil degistirildi.');
                },
              ),
              const _DividerLine(),
              _ToggleRow(
                key: const Key('setting_dark_mode'),
                icon: Icons.dark_mode_rounded,
                title: l10n.text('darkMode'),
                value: state.darkMode,
                onChanged: (value) {
                  controller.onToggleSetting(SettingToggle.darkMode, value);
                  _showSnack(
                    context,
                    value
                        ? 'Karanlik mod tercihi acildi.'
                        : 'Aydinlik mod tercihi acildi.',
                  );
                },
              ),
              const _DividerLine(),
              _ToggleRow(
                key: const Key('setting_high_quality'),
                icon: Icons.hd_rounded,
                title: l10n.text('highQuality'),
                value: state.highQualityConversion,
                badgeText: state.isPro ? 'PRO' : l10n.text('comingSoon'),
                onChanged: (value) {
                  if (!state.isPro && value) {
                    _showPremiumDialog(
                      context,
                      title: l10n.text('highQuality'),
                      message:
                          'Yuksek kalite donusum premium ozelligidir. Ucretsiz mod standart kaliteyi kullanir.',
                    );
                    return;
                  }
                  controller.onToggleSetting(
                    SettingToggle.highQualityConversion,
                    value,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: l10n.text('notifications')),
          _SettingsCard(
            children: [
              _ToggleRow(
                key: const Key('setting_push_notifications'),
                icon: Icons.notifications_active_outlined,
                title: l10n.text('pushNotifications'),
                value: state.pushNotifications,
                onChanged: (value) => controller.onToggleSetting(
                  SettingToggle.pushNotifications,
                  value,
                ),
              ),
              const _DividerLine(),
              _ToggleRow(
                key: const Key('setting_email_updates'),
                icon: Icons.mail_outline_rounded,
                title: l10n.text('emailUpdates'),
                value: state.emailUpdates,
                onChanged: (value) => controller.onToggleSetting(
                  SettingToggle.emailUpdates,
                  value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: l10n.text('support')),
          _SettingsCard(
            children: [
              _StaticRow(
                icon: Icons.help_outline_rounded,
                title: l10n.text('helpCenter'),
                onTap: () => _showInfoDialog(
                  context,
                  title: l10n.text('helpCenter'),
                  message:
                      'Kisa akis: PDF sec -> Donustur butonuna bas -> reklam kapaninca islem baslar -> indir.',
                ),
              ),
              const _DividerLine(),
              _StaticRow(
                icon: Icons.star_border_rounded,
                title: l10n.text('rateUs'),
                onTap: () => _showSnack(
                  context,
                  'Magaza linki henuz tanimli degil. Yayin oncesi eklenir.',
                ),
              ),
              const _DividerLine(),
              _StaticRow(
                icon: Icons.privacy_tip_outlined,
                title: l10n.text('privacyPolicy'),
                onTap: () => _showInfoDialog(
                  context,
                  title: l10n.text('privacyPolicy'),
                  message:
                      'Gizlilik politikasi bu prototipte placeholder. Yayin surumunde gercek metin/link eklenmeli.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.auth);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: palette.card,
                border: Border.all(color: palette.cardBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.text('logOut'),
                style: TextStyle(
                  fontSize: isCompact ? 22 : 26,
                  color: palette.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              l10n.text('version'),
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  Future<void> _showPremiumDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.palette.card,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.palette.card,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: context.palette.textSecondary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.palette.divider,
      height: 1,
      thickness: 1,
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({
    required this.icon,
    required this.title,
    this.trailingText,
    this.tagText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final String? tagText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (tagText != null) ...[
              const SizedBox(width: 6),
              _TagChip(label: tagText!),
            ],
            if (trailingText != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.badgeText,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            _TagChip(label: badgeText!),
          ],
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: palette.iconBoxBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: palette.iconBoxForeground),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.subtleBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: palette.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
