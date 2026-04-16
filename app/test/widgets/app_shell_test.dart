import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/providers/server_status_provider.dart';
import 'package:mgg_packify/widgets/app_shell.dart';

GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const Scaffold(body: Text('Dashboard body')),
          ),
          GoRoute(
            path: '/new-package',
            builder: (_, __) => const Scaffold(body: Text('New package body')),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => const Scaffold(body: Text('History body')),
          ),
        ],
      ),
    ],
  );
}

Widget _buildApp({required String initialLocation}) {
  final router = _router(initialLocation: initialLocation);
  return ProviderScope(
    overrides: [serverStatusProvider.overrideWith((ref) => ServerStatus.ready)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1920, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('AppShell sidebar interactions', () {
    testWidgets('shows active marker for current route item', (tester) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(_buildApp(initialLocation: '/history'));
      await tester.pumpAndSettle();

      // /history maps to index 3 in sidebar destinations.
      expect(find.byKey(const Key('sidebar-active-marker-3')), findsOneWidget);
      expect(find.byKey(const Key('sidebar-active-marker-1')), findsNothing);
    });

    testWidgets('hover applies visual delta on non-selected item', (
      tester,
    ) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(_buildApp(initialLocation: '/dashboard'));
      await tester.pumpAndSettle();

      final containerFinder = find.byKey(const Key('sidebar-item-1-container'));
      AnimatedContainer getContainer() =>
          tester.widget<AnimatedContainer>(containerFinder);

      Color? decorationColor(AnimatedContainer container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.color;
      }

      expect(decorationColor(getContainer()), Colors.transparent);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();

      await mouse.moveTo(tester.getCenter(containerFinder));
      await tester.pump(const Duration(milliseconds: 200));

      final hoveredColor = decorationColor(getContainer());
      expect(hoveredColor, isNotNull);
      expect(hoveredColor, isNot(equals(Colors.transparent)));
    });

    testWidgets('selection persists by route when navigating from sidebar', (
      tester,
    ) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(_buildApp(initialLocation: '/dashboard'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sidebar-active-marker-0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sidebar-item-1-inkwell')));
      await tester.pumpAndSettle();

      expect(find.text('New package body'), findsOneWidget);
      expect(find.byKey(const Key('sidebar-active-marker-1')), findsOneWidget);
      expect(find.byKey(const Key('sidebar-active-marker-0')), findsNothing);
    });
  });
}
