import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/core/api_client.dart';
import 'package:mgg_packgen/models/component_config.dart';
import 'package:mgg_packgen/models/options_model.dart';
import 'package:mgg_packgen/providers/options_provider.dart';
import 'package:mgg_packgen/widgets/component_detail_card.dart';

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
      home: Scaffold(
        body: SingleChildScrollView(
          child: ComponentDetailCard(
            type: type,
            instances: instances,
            onAdd: () {},
            onRemove: (_) {},
            onUpdate: (_, __) {},
          ),
        ),
      ),
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
  });
}
