import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packgen/core/api_client.dart';
import 'package:mgg_packgen/models/options_model.dart';
import 'package:mgg_packgen/models/package_list_item.dart';
import 'package:mgg_packgen/models/settings_model.dart';
import 'package:mgg_packgen/screens/clone_screen.dart';

// ─────────────────────────────────────────────
// Stub ApiClient — returns empty/safe defaults
// ─────────────────────────────────────────────

class _StubApiClient extends ApiClient {
  _StubApiClient() : super();

  @override
  Future<SettingsModel> getSettings() async => SettingsModel.empty();

  @override
  Future<List<PackageListItem>> listPackages(String baseDir) async => [];

  @override
  Future<OptionsModel> getOptions() async => OptionsModel(
    estatusList: const ['modificado', 'nuevo'],
    tipoSqlList: const [],
    tipoBlobList: const [],
  );
}

// ─────────────────────────────────────────────
// GoRouter with /home and /clone routes
// ─────────────────────────────────────────────

GoRouter get _testRouter => GoRouter(
  initialLocation: '/clone',
  routes: [
    GoRoute(path: '/clone', builder: (_, __) => const CloneScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => const Scaffold(body: Text('Home')),
    ),
  ],
);

Widget _buildApp() {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_StubApiClient())],
    child: MaterialApp.router(routerConfig: _testRouter),
  );
}

void main() {
  group('CloneScreen', () {
    testWidgets('renders a back arrow icon in the AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Task 4.1: AppBar leading must have Icons.arrow_back
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('AppBar shows "Clonar Package" title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Clonar Package'), findsOneWidget);
    });

    testWidgets('tapping back arrow navigates to /home', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // After navigation the Home scaffold text should appear
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
