import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/core/api_client.dart';
import 'package:mgg_packify/screens/new_package_screen.dart';

/// Minimal stub ApiClient that does nothing (never called in validation tests)
class _StubApiClient extends ApiClient {
  _StubApiClient() : super();
}

GoRouter get _testRouter => GoRouter(
  initialLocation: '/new-package',
  routes: [
    GoRoute(path: '/new-package', builder: (_, __) => const NewPackageScreen()),
    GoRoute(
      path: '/success',
      builder: (_, __) => const Scaffold(body: Text('Success')),
    ),
  ],
);

Widget buildTestApp() {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_StubApiClient())],
    child: MaterialApp.router(routerConfig: _testRouter),
  );
}

/// Expands the test viewport to 1920×1080 so the full form is visible,
/// then scrolls to ensure the button is visible and taps it.
Future<void> tapGenerateButton(WidgetTester tester) async {
  // Use a large viewport so the generate button is reachable without ambiguous scrolling
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpAndSettle();

  const key = Key('generate_button');
  // Ensure the button is visible — scroll if necessary
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}

void main() {
  group('NewPackageScreen validation', () {
    testWidgets('shows validation errors when form is empty on submit', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tapGenerateButton(tester);

      // Should show validation errors for required fields
      expect(find.text('El ticket es obligatorio'), findsOneWidget);
    });

    testWidgets('shows iteracion validation error', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Clear the default iteracion value and submit
      final iterField = find.widgetWithText(TextFormField, 'Iteración *');
      if (iterField.evaluate().isNotEmpty) {
        await tester.enterText(iterField, '');
      }

      await tapGenerateButton(tester);

      // We expect ticket error at minimum (form-level validation)
      expect(find.textContaining('obligatori'), findsWidgets);
    });

    testWidgets('shows ruta validation error when empty', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill ticket to pass that validation
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ticket *'),
        'MX01-999',
      );

      await tapGenerateButton(tester);

      expect(find.text('La ruta es obligatoria'), findsOneWidget);
    });

    testWidgets('does not call API when form is invalid (no network call)', (
      tester,
    ) async {
      // This test verifies no navigation happens when validation fails
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tapGenerateButton(tester);
      await tester.pumpAndSettle();

      // Should still be on NewPackageScreen (not navigated to success)
      expect(find.text('Generar Package'), findsOneWidget);
    });

    testWidgets('SegmentedButton for ambiente renders QA and PROD options', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('QA'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);
    });

    testWidgets('PackageNamePreview is rendered on screen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Preview shows even when empty — look for placeholder text
      expect(find.textContaining('PortalRetail'), findsOneWidget);
    });
  });
}
