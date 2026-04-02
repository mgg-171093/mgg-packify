import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/generate_result.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/clone_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_package_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/success_screen.dart';

// ─────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/new-package',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NewPackageScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, anim, _, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    ),
    GoRoute(
      path: '/success',
      pageBuilder: (ctx, state) {
        final result = state.extra as GenerateResult;
        return CustomTransitionPage(
          key: state.pageKey,
          child: SuccessScreen(result: result),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (ctx, anim, _, child) {
            final tween = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut));
            return SlideTransition(position: anim.drive(tween), child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/clone',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CloneScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, anim, _, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, anim, _, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HistoryScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, anim, _, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    ),
  ],
);

// ─────────────────────────────────────────────
// App
// ─────────────────────────────────────────────

class App extends ConsumerWidget {
  const App({super.key});

  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'MGG-Packify',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
