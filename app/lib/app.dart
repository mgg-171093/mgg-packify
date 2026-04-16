import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/generate_result.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/about_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/catalogos/bases_datos_screen.dart';
import 'screens/catalogos/doc_templates_screen.dart';
import 'screens/catalogos/estatus_screen.dart';
import 'screens/catalogos/servidores_screen.dart';
import 'screens/catalogos/projects_screen.dart';
import 'screens/catalogos/servicios_screen.dart';
import 'screens/catalogos/tipos_screen.dart';
import 'screens/clone_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/log_viewer_screen.dart';
import 'screens/new_package_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/success_screen.dart';
import 'screens/templates_screen.dart';
import 'widgets/app_shell.dart';

// ─────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Outside the shell — no sidebar ────────────────────────────────
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
    // /home → redirect to /dashboard (backwards compatibility)
    GoRoute(path: '/home', redirect: (ctx, state) => '/dashboard'),
    // /settings → redirect to /settings/appearance (backwards compatibility)
    GoRoute(
      path: '/settings',
      redirect: (ctx, state) => '/settings/appearance',
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
    // ── Inside the shell — with sidebar ───────────────────────────────
    ShellRoute(
      builder: (ctx, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/new-package',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: NewPackageScreen()),
        ),
        GoRoute(
          path: '/clone',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: CloneScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/templates',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: TemplatesScreen()),
        ),
        GoRoute(
          path: '/settings/appearance',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: AppearanceScreen()),
        ),
        GoRoute(
          path: '/catalogos/proyectos',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(child: ProjectsScreen(returnTo: returnTo));
          },
        ),
        GoRoute(
          path: '/catalogos/servidores',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(
              child: ServidoresScreen(returnTo: returnTo),
            );
          },
        ),
        GoRoute(
          path: '/catalogos/servicios',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(child: ServiciosScreen(returnTo: returnTo));
          },
        ),
        GoRoute(
          path: '/catalogos/estatus',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(child: EstatusScreen(returnTo: returnTo));
          },
        ),
        GoRoute(
          path: '/catalogos/bases-datos',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(
              child: BasesDatosScreen(returnTo: returnTo),
            );
          },
        ),
        GoRoute(
          path: '/catalogos/tipos',
          pageBuilder: (ctx, state) {
            final returnTo = state.extra as String?;
            return NoTransitionPage(child: TiposScreen(returnTo: returnTo));
          },
        ),
        GoRoute(
          path: '/catalogos/doc-templates',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: DocTemplatesScreen()),
        ),
        GoRoute(
          path: '/logs',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: LogViewerScreen()),
        ),
        GoRoute(
          path: '/about',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: AboutScreen()),
        ),
      ],
    ),
  ],
);

// ─────────────────────────────────────────────
// App
// ─────────────────────────────────────────────

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'MGG-Packify',
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
