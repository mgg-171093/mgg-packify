import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/core/api_client.dart';
import 'package:mgg_packify/core/theme/app_theme.dart';
import 'package:mgg_packify/core/theme/theme_extensions.dart';
import 'package:mgg_packify/models/component_config.dart';
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/providers/options_provider.dart';
import 'package:mgg_packify/widgets/component_detail_card.dart';

// ─────────────────────────────────────────────
// Stub ApiClient for widget tests
// ─────────────────────────────────────────────

class _StubApiClient extends ApiClient {
  final OptionsModel _options;
  _StubApiClient(this._options) : super();

  @override
  Future<OptionsModel> getOptions() async => _options;

  @override
  Future<OptionsModel> putOptions(OptionsModel opts) async => opts;
}

// ─────────────────────────────────────────────
// Helper: build the card inside ProviderScope + MaterialApp
// ─────────────────────────────────────────────

Widget _buildCard({
  required ComponentType type,
  required List<ComponentInstanceState> instances,
  OptionsModel? options,
  String? returnTo,
}) {
  final opts =
      options ??
      OptionsModel(
        estatusList: const ['modificado', 'nuevo'],
        tipoSqlList: const ['sp', 'trigger', 'script', 'job'],
        tipoBlobList: const ['css', 'scss', 'js'],
      );

  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_StubApiClient(opts))],
    child: MaterialApp(
      theme: appTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ComponentDetailCard(
            type: type,
            instances: instances,
            onAdd: () {},
            onRemove: (_) {},
            onUpdate: (_, __) {},
            returnTo: returnTo,
          ),
        ),
      ),
    ),
  );
}

/// Build the card wrapped in a GoRouter for navigation tests.
Widget _buildCardWithRouter({
  required ComponentType type,
  required List<ComponentInstanceState> instances,
  OptionsModel? options,
  String? returnTo,
  List<String> navigatedRoutes = const [],
}) {
  final opts =
      options ??
      OptionsModel(
        estatusList: const ['modificado', 'nuevo'],
        tipoSqlList: const ['sp'],
        tipoBlobList: const ['css'],
      );

  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (ctx, state) => Scaffold(
          body: SingleChildScrollView(
            child: ComponentDetailCard(
              type: type,
              instances: instances,
              onAdd: () {},
              onRemove: (_) {},
              onUpdate: (_, __) {},
              returnTo: returnTo,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/catalogos/servicios',
        builder: (ctx, state) =>
            const Scaffold(body: Text('Servicios Catalog')),
      ),
      GoRoute(
        path: '/catalogos/bases-datos',
        builder: (ctx, state) =>
            const Scaffold(body: Text('Bases Datos Catalog')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_StubApiClient(opts))],
    child: MaterialApp.router(
      theme: appTheme(Brightness.light),
      routerConfig: router,
    ),
  );
}

void main() {
  group('ComponentDetailCard', () {
    // ── estatus dropdown: all types ────────────────

    testWidgets('renders estatus dropdown for sql type', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [ComponentInstanceState(scripts: const [])],
        ),
      );
      await tester.pumpAndSettle();

      // The dropdown label "Estatus" should be visible
      expect(find.text('Estatus'), findsOneWidget);
    });

    testWidgets('renders estatus dropdown for api_iis type', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiIis,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estatus'), findsOneWidget);
    });

    testWidgets('renders estatus dropdown for blob type', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.blob,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estatus'), findsOneWidget);
    });

    testWidgets('renders estatus dropdown for liferay_build type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.liferayBuild,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estatus'), findsOneWidget);
    });

    // ── tipo dropdown: sql and blob only ──────────

    testWidgets('renders tipo dropdown for sql type', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [ComponentInstanceState(scripts: const [])],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo'), findsOneWidget);
    });

    testWidgets('renders tipo dropdown for blob type', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.blob,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo'), findsOneWidget);
    });

    // ── tipo dropdown HIDDEN for api_iis ──────────

    testWidgets('does NOT render tipo dropdown for api_iis type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiIis,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      // api_iis should not have a Tipo label
      expect(find.text('Tipo'), findsNothing);
    });

    testWidgets('does NOT render tipo dropdown for liferay_build type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.liferayBuild,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo'), findsNothing);
    });

    testWidgets('does NOT render tipo dropdown for api_docker type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiDocker,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo'), findsNothing);
    });

    // ── estatus dropdown shows options from provider ──

    testWidgets('estatus dropdown contains items from OptionsModel', (
      tester,
    ) async {
      final customOptions = OptionsModel(
        estatusList: const ['modificado', 'nuevo', 'eliminado'],
        tipoSqlList: const ['sp'],
        tipoBlobList: const ['css'],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [ComponentInstanceState(scripts: const [])],
          options: customOptions,
        ),
      );
      await tester.pumpAndSettle();

      // The options are loaded — verify the first item in the dropdown is shown
      // The current value ('modificado') should be visible as the selected item.
      expect(find.text('modificado'), findsOneWidget);
    });

    // ── card header shows type label ──────────────

    testWidgets('card renders the component type label in header', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [ComponentInstanceState(scripts: const [])],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ComponentType.sql.label), findsOneWidget);
    });

    testWidgets('card uses SurfaceTokens.cardElevated for surface color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [const ComponentInstanceState(scripts: [])],
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card).first);
      final context = tester.element(find.byType(ComponentDetailCard));
      final theme = Theme.of(context);
      final surfaces =
          theme.extension<SurfaceTokens>() ??
          SurfaceTokens.fromColorScheme(theme.colorScheme);

      expect(card.color, equals(surfaces.cardElevated));
    });

    testWidgets('header tap collapses and re-expands body', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [
            const ComponentInstanceState(scripts: ['a.sql']),
          ],
        ),
      );
      await tester.pumpAndSettle();

      AnimatedRotation rotation = tester.widget(find.byType(AnimatedRotation));
      expect(rotation.turns, 0);

      await tester.tap(find.text(ComponentType.sql.label));
      await tester.pump(const Duration(milliseconds: 300));
      rotation = tester.widget(find.byType(AnimatedRotation));
      expect(rotation.turns, -0.25);

      await tester.tap(find.text(ComponentType.sql.label));
      await tester.pump(const Duration(milliseconds: 300));
      rotation = tester.widget(find.byType(AnimatedRotation));
      expect(rotation.turns, 0);
    });

    // ── image-picker IconButton (Task 4.2) ────────

    testWidgets(
      'api_iis card with 1 config row shows add_photo_alternate_outlined icon',
      (tester) async {
        await tester.pumpWidget(
          _buildCard(
            type: ComponentType.apiIis,
            instances: [
              const ComponentInstanceState(
                configs: [ConfigEntry(clave: 'k', valor: 'v')],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Task 4.2: one config row → one image-picker IconButton
        expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'api_iis card with 2 config rows shows 2 image-picker IconButtons',
      (tester) async {
        await tester.pumpWidget(
          _buildCard(
            type: ComponentType.apiIis,
            instances: [
              const ComponentInstanceState(
                configs: [
                  ConfigEntry(clave: 'k1', valor: 'v1'),
                  ConfigEntry(clave: 'k2', valor: 'v2'),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.add_photo_alternate_outlined),
          findsNWidgets(2),
        );
      },
    );

    // ── image icon when imagenPath already set (Task 4.3) ─────

    testWidgets(
      'api_iis config row with imagenPath set shows Icons.image instead of add_photo',
      (tester) async {
        await tester.pumpWidget(
          _buildCard(
            type: ComponentType.apiIis,
            instances: [
              const ComponentInstanceState(
                configs: [
                  ConfigEntry(
                    clave: 'k',
                    valor: 'v',
                    imagenPath: '/path/to/image.png',
                  ),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // A pre-set imagenPath → icon must be Icons.image, NOT add_photo
        expect(find.byIcon(Icons.image), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
      },
    );

    testWidgets('api_iis mixed config rows: one without imagenPath, one with', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiIis,
          instances: [
            const ComponentInstanceState(
              configs: [
                ConfigEntry(clave: 'k1', valor: 'v1'),
                ConfigEntry(
                  clave: 'k2',
                  valor: 'v2',
                  imagenPath: '/some/path.jpg',
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Row 1 (no imagenPath) → add_photo icon
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      // Row 2 (imagenPath set) → image icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    // ── E.9: Empty service prompts ────────────────

    testWidgets('api_iis with empty services shows _EmptyServicePrompt', (
      tester,
    ) async {
      final emptyOptions = OptionsModel(
        estatusList: const ['modificado'],
        tipoSqlList: const [],
        tipoBlobList: const [],
        apiIisServices: const [],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiIis,
          instances: [const ComponentInstanceState()],
          options: emptyOptions,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay servicios IIS configurados.'), findsOneWidget);
      expect(find.text('Ir al catálogo'), findsOneWidget);
    });

    testWidgets('api_iis with services shows "Gestionar catálogo" link', (
      tester,
    ) async {
      final optionsWithServices = OptionsModel(
        estatusList: const ['modificado'],
        tipoSqlList: const [],
        tipoBlobList: const [],
        apiIisServices: const [
          ApiIisServiceEntry(nombre: 'Svc1', ruta: '/ruta1'),
        ],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiIis,
          instances: [const ComponentInstanceState()],
          options: optionsWithServices,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestionar catálogo'), findsOneWidget);
      // No empty prompt
      expect(find.text('No hay servicios IIS configurados.'), findsNothing);
    });

    testWidgets('api_docker with empty services shows _EmptyServicePrompt', (
      tester,
    ) async {
      final emptyOptions = OptionsModel(
        estatusList: const ['modificado'],
        tipoSqlList: const [],
        tipoBlobList: const [],
        apiDockerServices: const [],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiDocker,
          instances: [const ComponentInstanceState()],
          options: emptyOptions,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay servicios Docker configurados.'),
        findsOneWidget,
      );
      expect(find.text('Ir al catálogo'), findsOneWidget);
    });

    testWidgets('api_docker shows Jenkins and APIM switches with default ON', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.apiDocker,
          instances: [const ComponentInstanceState()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jenkins CI/CD'), findsOneWidget);
      expect(find.text('Actualizar APIM'), findsOneWidget);

      // Both switches should be ON by default
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      // There are 2 switches (jenkins + actualizarApim)
      expect(switches.length, greaterThanOrEqualTo(2));
      // Find by label position — check both are true by default
      final jenkinsSwitch = switches[0];
      final apimSwitch = switches[1];
      expect(jenkinsSwitch.value, isTrue);
      expect(apimSwitch.value, isTrue);
    });

    testWidgets('sql with empty databases shows _EmptyServicePrompt', (
      tester,
    ) async {
      final emptyOptions = OptionsModel(
        estatusList: const ['modificado'],
        tipoSqlList: const ['sp'],
        tipoBlobList: const [],
        sqlDatabases: const [],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [const ComponentInstanceState(scripts: [])],
          options: emptyOptions,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay bases de datos configuradas.'), findsOneWidget);
      expect(find.text('Ir al catálogo'), findsOneWidget);
    });

    testWidgets('sql with databases shows "Gestionar catálogo" link', (
      tester,
    ) async {
      final optionsWithDbs = OptionsModel(
        estatusList: const ['modificado'],
        tipoSqlList: const ['sp'],
        tipoBlobList: const [],
        sqlDatabases: const ['DB_QA', 'DB_PROD'],
      );

      await tester.pumpWidget(
        _buildCard(
          type: ComponentType.sql,
          instances: [const ComponentInstanceState(scripts: [])],
          options: optionsWithDbs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestionar catálogo'), findsOneWidget);
      expect(find.text('No hay bases de datos configuradas.'), findsNothing);
    });
  });
}
