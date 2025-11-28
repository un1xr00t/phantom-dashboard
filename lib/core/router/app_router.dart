// lib/core/router/app_router.dart
import 'package:flutter/material.dart';

import '../../../../features/splash/screens/splash_screen.dart';
import '../../../../features/auth/screens/setup_screen.dart';
import '../../../../features/dashboard/screens/main_shell.dart';
import '../../../../features/dashboard/screens/dashboard_screen.dart';
import '../../../../features/dropbox/screens/dropbox_detail_screen.dart';
import '../../../../features/loot/screens/loot_browser_screen.dart';
import '../../../../features/loot/screens/credential_detail_screen.dart';
import '../../../../features/alerts/screens/alerts_screen.dart';
import '../../../../features/commands/screens/command_center_screen.dart';
import '../../../../features/recon/screens/network_map_screen.dart';
import '../../../../features/settings/screens/settings_screen.dart';
import '../../../../features/settings/screens/c2_config_screen.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String setup = '/setup';
  static const String main = '/main';
  static const String dashboard = '/dashboard';
  static const String dropboxDetail = '/dropbox/detail';
  static const String lootBrowser = '/loot';
  static const String credentialDetail = '/loot/credential';
  static const String alerts = '/alerts';
  static const String commandCenter = '/commands';
  static const String networkMap = '/network';
  static const String settings = '/settings';
  static const String c2Config = '/settings/c2';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);

      case setup:
        return _slideRoute(const SetupScreen(), settings);

      case main:
        return _fadeRoute(const MainShell(), settings);

      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);

      case dropboxDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          DropboxDetailScreen(dropboxId: args?['dropboxId'] ?? ''),
          settings,
        );

      case lootBrowser:
        return _slideRoute(const LootBrowserScreen(), settings);

      case credentialDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          CredentialDetailScreen(credentialId: args?['credentialId'] ?? ''),
          settings,
        );

      case alerts:
        return _slideRoute(const AlertsScreen(), settings);

      case commandCenter:
        return _slideRoute(const CommandCenterScreen(), settings);

      case networkMap:
        return _slideRoute(const NetworkMapScreen(), settings);

      case AppRouter.settings:
        return _slideRoute(const SettingsScreen(), settings);

      case c2Config:
        return _slideRoute(const C2ConfigScreen(), settings);

      default:
        return _fadeRoute(
          Scaffold(
            body: Center(
              child: Text(
                '404 - Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          settings,
        );
    }
  }

  // Fade transition for main screens
  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide transition for detail screens
  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Scale transition for modals/dialogs
  static PageRouteBuilder _scaleRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;

        var scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// Navigation helper extension
extension NavigationExtension on BuildContext {
  void pushNamed(String routeName, {Object? arguments}) {
    Navigator.pushNamed(this, routeName, arguments: arguments);
  }

  void pushReplacementNamed(String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(this, routeName, arguments: arguments);
  }

  void pushNamedAndRemoveUntil(String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      this,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void pop<T>([T? result]) {
    Navigator.pop(this, result);
  }

  bool canPop() {
    return Navigator.canPop(this);
  }
}