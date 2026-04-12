import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/models/package_history_entry.dart';
import 'package:mgg_packify/models/settings_model.dart';
import 'package:mgg_packify/providers/health_polling_provider.dart';
import 'package:mgg_packify/providers/history_provider.dart';
import 'package:mgg_packify/providers/options_provider.dart';
import 'package:mgg_packify/providers/settings_provider.dart';
import 'package:mgg_packify/providers/update_check_provider.dart';
import 'package:mgg_packify/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

PackageHistoryEntry _entry({
  String ticket = 'TKT-001',
  String ambiente = 'QA',
  String packageName = 'TKT-001-PortalRetail_QA-01',
  DateTime? generatedAt,
}) {
  return PackageHistoryEntry(
    ticket: ticket,
    ambiente: ambiente,
    iteracion: '01',
    packageName: packageName,
    packageDir: r'C:\Packages',
    generatedAt: generatedAt ?? DateTime.now(),
  );
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(
      path: '/new-package',
      builder: (_, __) => const Scaffold(body: Text('NewPackage')),
    ),
    GoRoute(
      path: '/history',
      builder: (_, __) => const Scaffold(body: Text('History')),
    ),
  ],
);

Widget _buildApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      updateCheckProvider.overrideWith(_FakeUpdateCheckNotifier.new),
      healthPollingProvider.overrideWith(_FakeHealthPollingNotifier.new),
      ...overrides,
    ],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
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

class _FakeSettingsNotifier extends AsyncNotifier<SettingsModel>
    implements SettingsNotifier {
  _FakeSettingsNotifier(this._settings);
  final SettingsModel _settings;

  @override
  Future<SettingsModel> build() async => _settings;

  @override
  Future<void> save(SettingsModel settings) async {}

  @override
  void clear() {}
}

class _FakeOptionsNotifier extends AsyncNotifier<OptionsModel>
    implements OptionsNotifier {
  _FakeOptionsNotifier(this._options);
  final OptionsModel _options;

  @override
  Future<OptionsModel> build() async => _options;

  @override
  Future<void> save(OptionsModel options) async {}
}

class _FakeUpdateCheckNotifier extends UpdateCheckNotifier {
  @override
  Future<UpdateCheckState> build() async => UpdateCheckState.none();

  @override
  Future<void> checkForUpdates({http.Client? client}) async {}
}

class _FakeHealthPollingNotifier extends HealthPollingNotifier {
  @override
  void build() {}

  @override
  void startPolling() {}

  @override
  void stopPolling() {}
}

// ─────────────────────────────────────────────
// DashboardMetrics unit tests
// ─────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DashboardMetrics', () {
    test('total() returns count of all entries', () {
      final entries = [_entry(), _entry(), _entry()];
      final metrics = DashboardMetrics(entries);
      expect(metrics.total(), 3);
    });

    test('total() is 0 when empty', () {
      expect(DashboardMetrics([]).total(), 0);
    });

    test('today() counts only entries from today', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final entries = [
        _entry(generatedAt: now),
        _entry(generatedAt: now),
        _entry(generatedAt: yesterday),
      ];
      final metrics = DashboardMetrics(entries);
      expect(metrics.today(), 2);
    });

    test('thisWeek() counts entries from current week', () {
      final now = DateTime.now();
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      final entries = [
        _entry(generatedAt: now),
        _entry(generatedAt: twoWeeksAgo),
      ];
      final metrics = DashboardMetrics(entries);
      expect(metrics.thisWeek(), 1);
    });

    test('byAmbiente() groups entries by ambiente', () {
      final entries = [
        _entry(ambiente: 'QA'),
        _entry(ambiente: 'QA'),
        _entry(ambiente: 'PROD'),
      ];
      final metrics = DashboardMetrics(entries);
      final byAmbiente = metrics.byAmbiente();
      expect(byAmbiente['QA'], 2);
      expect(byAmbiente['PROD'], 1);
    });

    test('recent(5) returns up to 5 most recent entries', () {
      final entries = List.generate(10, (i) => _entry(ticket: 'TKT-$i'));
      final metrics = DashboardMetrics(entries);
      expect(metrics.recent(5).length, 5);
    });

    test('recent(5) returns all entries when fewer than 5', () {
      final entries = [_entry(), _entry()];
      final metrics = DashboardMetrics(entries);
      expect(metrics.recent(5).length, 2);
    });
  });

  // ─────────────────────────────────────────────
  // DashboardScreen widget tests
  // ─────────────────────────────────────────────

  group('DashboardScreen — empty state', () {
    testWidgets('renders Dashboard title', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier([])),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('shows empty state message when no packages', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier([])),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todavía no generaste ningún package'), findsOneWidget);
    });

    testWidgets('shows "Nuevo Package" button in empty state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier([])),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Package'), findsOneWidget);
    });
  });

  group('DashboardScreen — with entries', () {
    testWidgets('renders metric cards with correct values', (tester) async {
      final entries = [
        _entry(packageName: 'PKG-001'),
        _entry(packageName: 'PKG-002'),
      ];
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // "Total" metric should show 2
      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('renders recent package names', (tester) async {
      final entries = [
        _entry(packageName: 'INC-001-PortalRetail_QA-01'),
        _entry(packageName: 'INC-002-PortalRetail_PROD-02'),
      ];
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier(entries)),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INC-001-PortalRetail_QA-01'), findsOneWidget);
      expect(find.text('INC-002-PortalRetail_PROD-02'), findsOneWidget);
    });
  });

  group('DashboardScreen — config status', () {
    testWidgets('shows "Sin configurar" when QA not set', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier([])),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(SettingsModel.empty()),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin configurar'), findsWidgets);
    });

    testWidgets('shows "Configurado" when QA is set', (tester) async {
      final settings = SettingsModel(
        qa: const ServerConfigModel(
          api: '10.42.55.25',
          bd: '',
          blob: '',
          liferay: '',
        ),
        prod: ServerConfigModel.empty(),
      );
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            historyProvider.overrideWith(() => _FakeHistoryNotifier([])),
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(settings),
            ),
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurado'), findsOneWidget);
    });
  });
}
