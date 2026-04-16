import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/providers/options_provider.dart';
import 'package:mgg_packify/screens/catalogos/servicios_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOptionsNotifier extends AsyncNotifier<OptionsModel>
    implements OptionsNotifier {
  _FakeOptionsNotifier(this._options);

  final OptionsModel _options;
  OptionsModel? lastSaved;

  @override
  Future<OptionsModel> build() async => _options;

  @override
  Future<void> save(OptionsModel options) async {
    lastSaved = options;
    state = AsyncData(options);
  }
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/catalogos/servicios',
  routes: [
    GoRoute(
      path: '/catalogos/servicios',
      builder: (_, __) => const ServiciosScreen(),
    ),
    GoRoute(path: '/dashboard', builder: (_, __) => const SizedBox.shrink()),
  ],
);

Widget _buildApp(_FakeOptionsNotifier fakeNotifier) {
  return ProviderScope(
    overrides: [optionsProvider.overrideWith(() => fakeNotifier)],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('usa colores semánticos en acciones de edición y eliminación', (
    tester,
  ) async {
    final fake = _FakeOptionsNotifier(
      const OptionsModel(
        apiIisServices: [ApiIisServiceEntry(nombre: 'Svc A', ruta: 'a.csproj')],
      ),
    );

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    // Entrar en modo edición para exponer confirmar/cancelar.
    await tester.tap(find.byTooltip('Editar').first);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ServiciosScreen));
    final colorScheme = Theme.of(context).colorScheme;

    final confirmButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.check).first,
    );
    final confirmIcon = confirmButton.icon as Icon;
    expect(confirmIcon.color, colorScheme.primary);

    final cancelButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close).first,
    );
    final cancelIcon = cancelButton.icon as Icon;
    expect(cancelIcon.color, colorScheme.error);

    // Eliminar (fuera del modo edición) mantiene color semántico de error.
    await tester.tap(find.byTooltip('Cancelar').first);
    await tester.pumpAndSettle();

    final deleteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outlined).first,
    );
    expect(deleteButton.color, colorScheme.error);
  });

  testWidgets(
    'muestra helper text y cursor de texto en campos inline y add-row',
    (tester) async {
      final fake = _FakeOptionsNotifier(
        const OptionsModel(
          apiIisServices: [ApiIisServiceEntry(nombre: 'Svc A', ruta: '')],
        ),
      );

      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();

      // Add-row helper hierarchy.
      expect(find.text('Campo requerido'), findsOneWidget);
      expect(find.text('Opcional'), findsOneWidget);

      // Text-entry affordance: los TextField están envueltos en MouseRegion(text).
      final textMouseRegions = find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.text,
        description: 'MouseRegion with text cursor',
      );
      expect(textMouseRegions, findsAtLeastNWidgets(2));

      // Inline edit helper text.
      await tester.tap(find.byTooltip('Editar').first);
      await tester.pumpAndSettle();

      expect(find.text('Editá y confirmá para guardar'), findsOneWidget);
      expect(find.text('Podés pegar la ruta o buscar archivo'), findsOneWidget);
    },
  );
}
