import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/app/router.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/app_gradient_background.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';
import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  static const routePath = AppRoutes.auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final l10n = context.l10n;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    key: const Key('screen_auth'),
                    children: [
                      const SizedBox(height: 54),
                      const _AuthLogo(),
                      const SizedBox(height: 30),
                      Text(
                        l10n.text('appName'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.text('authSubtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _PrimaryButton(
                        key: const Key('auth_start_button'),
                        label: l10n.text('startConverting'),
                        onTap: () => context.go(AppRoutes.convert),
                      ),
                      const SizedBox(height: 14),
                      _SocialButton(
                        key: const Key('auth_apple_button'),
                        label: l10n.text('continueApple'),
                        icon: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 24,
                        ),
                        background: Colors.white,
                        textColor: Colors.black,
                        loading: authState.isLoading &&
                            authState.currentProvider == AuthProviderType.apple,
                        onTap: () => _signIn(
                          context,
                          ref,
                          AuthProviderType.apple,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SocialButton(
                        key: const Key('auth_google_button'),
                        label: l10n.text('continueGoogle'),
                        icon: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F6FF),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        background: Colors.white,
                        textColor: const Color(0xFF22304A),
                        loading: authState.isLoading &&
                            authState.currentProvider ==
                                AuthProviderType.google,
                        onTap: () => _signIn(
                          context,
                          ref,
                          AuthProviderType.google,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: palette.divider),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              l10n.text('or'),
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: palette.divider),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _OutlineButton(
                        key: const Key('auth_email_button'),
                        label: l10n.text('signInEmail'),
                        icon: const Icon(Icons.mail_outline, size: 22),
                        loading: authState.isLoading &&
                            authState.currentProvider == AuthProviderType.email,
                        onTap: () => _signIn(
                          context,
                          ref,
                          AuthProviderType.email,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(text: '${l10n.text('termsPrefix')} '),
                            TextSpan(
                              text: l10n.text('terms'),
                              style: TextStyle(color: palette.primary),
                            ),
                            TextSpan(text: ' ${l10n.text('and')} '),
                            TextSpan(
                              text: l10n.text('privacy'),
                              style: TextStyle(color: palette.primary),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    AuthProviderType provider,
  ) async {
    await ref.read(authControllerProvider.notifier).signIn(provider);
    if (context.mounted) {
      context.go(AppRoutes.convert);
    }
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(36);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: palette.glow,
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: ColoredBox(
              color: const Color(0xFF0B2DB1),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.cardBorder, width: 2),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: palette.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 72,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: palette.glow,
              blurRadius: 20,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.textColor,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color textColor;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      child: Container(
        height: 78,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: textColor,
                ),
              )
            else
              icon,
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: loading ? null : onTap,
      child: Container(
        height: 78,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.cardBorder, width: 2),
          color: isDark ? const Color(0x330E1A34) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: palette.textPrimary,
                ),
              )
            else
              icon,
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
