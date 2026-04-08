import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/models/package_history_entry.dart';
import 'package:mgg_packify/providers/history_provider.dart';
import 'package:mgg_packify/providers/package_form_provider.dart';
import 'package:mgg_packify/screens/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

PackageHistoryEntry _entry({
  String ticket = 'TKT-001',
  String ambiente = 'QA',
  String packageName = 'TKT-001-PortalRetail_QA-01',
}) {
  return PackageHistoryEntry(
    ticket: ticket,
    ambiente: ambiente,
    iteracion: '01',
    packageName: packageName,
    packageDir: r'C:\Packages',
    generatedAt: DateTime.utc(2026, 4, 1),
  );
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/history',
  routes: [
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/new-package',
      builder: (_, __) => const Scaffold(body: Text('NewPackage')),
    ),
  ],
);

Widget _buildApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

// ─────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryScreen — empty state', () {
    testWidgets('renders empty state without crash when no entries', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Empty state text
      expect(find.text('No hay packages generados aún'), findsOneWidget);
    });

    testWidgets('shows history icon in empty state', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('HistoryScreen — with entries', () {
    testWidgets('renders entry package names from provider', (tester) async {
      final entries = [
        _entry(
          ticket: 'INC-100',
          packageName: 'INC-100-PortalRetail_QA-01',
          ambiente: 'QA',
        ),
        _entry(
          ticket: 'INC-200',
          packageName: 'INC-200-PortalRetail_PROD-02',
          ambiente: 'PROD',
        ),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INC-100-PortalRetail_QA-01'), findsOneWidget);
      expect(find.text('INC-200-PortalRetail_PROD-02'), findsOneWidget);
    });

    testWidgets('renders ambiente chip for each entry', (tester) async {
      final entries = [
        _entry(ambiente: 'QA', packageName: 'PKG-QA'),
        _entry(ambiente: 'PROD', packageName: 'PKG-PROD'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QA'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);
    });

    testWidgets('tapping entry navigates to /new-package', (tester) async {
      final entries = [_entry(packageName: 'TKT-001-PortalRetail_QA-01')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
            packageFormProvider.overrideWith(() => _FakePackageFormNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TKT-001-PortalRetail_QA-01'));
      await tester.pumpAndSettle();

      expect(find.text('NewPackage'), findsOneWidget);
    });
  });

  group('HistoryScreen — AppBar', () {
    testWidgets('shows "Historial" title in AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Historial'), findsOneWidget);
    });

    testWidgets('does NOT show back arrow (sidebar navigation replaces it)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // In the new shell layout the leading back arrow was removed.
      // The persistent sidebar handles back/home navigation.
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows clear icon when entries exist', (tester) async {
      final entries = [_entry()];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    });

    testWidgets('does NOT show clear icon when list is empty', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_sweep_outlined), findsNothing);
    });
  });
}

// ─────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────

class _FakeHistoryNotifier extends AsyncNotifier<List<PackageHistoryEntry>>
    implements HistoryNotifier {
  _FakeHistoryNotifier(this._entries);

  final List<PackageHistoryEntry> _entries;

  @override
  Future<List<PackageHistoryEntry>> build() async => _entries;

  @override
  Future<void> add(PackageHistoryEntry entry) async {}

  @override
  Future<void> delete(int index) async {}

  @override
  Future<void> clear() async {}
}

class _FakePackageFormNotifier extends PackageFormNotifier {
  @override
  void prefillFromHistory(PackageHistoryEntry entry) {
    // no-op in test
  }
}
