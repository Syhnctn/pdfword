import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/core/widgets/main_shell.dart';
import 'package:pdfword_pro/features/auth/presentation/auth_screen.dart';
import 'package:pdfword_pro/features/convert/presentation/convert_screen.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_screen.dart';
import 'package:pdfword_pro/features/history/presentation/history_screen.dart';
import 'package:pdfword_pro/features/settings/presentation/settings_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const auth = '/auth';
  static const convert = '/convert';
  static const history = '/history';
  static const settings = '/settings';
  static const preview = '/preview';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) {
          return _fadeSlidePage(
            state: state,
            child: const AuthScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.preview,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _fadeSlidePage(
            state: state,
            child: PreviewScreen(
              details: extra is PreviewDetails ? extra : null,
            ),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.convert,
            pageBuilder: (context, state) {
              return _fadeSlidePage(
                state: state,
                child: const ConvertScreen(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) {
              return _fadeSlidePage(
                state: state,
                child: const HistoryScreen(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) {
              return _fadeSlidePage(
                state: state,
                child: const SettingsScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 110),
    reverseTransitionDuration: const Duration(milliseconds: 90),
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) return page;

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.01),
            end: Offset.zero,
          ).animate(curved),
          child: page,
        ),
      );
    },
  );
}
