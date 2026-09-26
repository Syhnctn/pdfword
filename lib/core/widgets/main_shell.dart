import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/core/ads/app_banner_ad.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/app_bottom_nav.dart';
import 'package:pdfword_pro/core/widgets/app_gradient_background.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  AppTab get _currentTab {
    if (location.startsWith('/history')) return AppTab.history;
    if (location.startsWith('/settings')) return AppTab.settings;
    return AppTab.convert;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _currentTab;
    final palette = context.palette;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          top: true,
          bottom: false,
          child: child,
        ),
      ),
      floatingActionButton: currentTab == AppTab.history
          ? Pressable(
              onTap: () => context.go(AppTab.convert.path),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary,
                  boxShadow: [
                    BoxShadow(
                      color: palette.glow,
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 36, color: Colors.white),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBannerAd(),
          AppBottomNav(
            currentTab: currentTab,
            onChanged: (next) {
              if (next != currentTab) {
                context.go(next.path);
              }
            },
          ),
        ],
      ),
    );
  }
}
