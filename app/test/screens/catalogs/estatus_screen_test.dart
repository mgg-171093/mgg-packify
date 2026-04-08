import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/providers/options_provider.dart';
import 'package:mgg_packify/screens/catalogos/estatus_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────

class _FakeOptionsNotifier extends AsyncNotifier<OptionsModel>
    implements OptionsNotifier {
  _FakeOptionsNotifier(this._options);
  final OptionsModel _options;
  OptionsModel _current = OptionsModel.empty();

  @override
  Future<OptionsModel> build() async {
    _current = _options;
    return _options;
  }

  @override
  Future<void> save(OptionsModel options) async {
    _current = options;
    state = AsyncData(options);
  }
}

GoRouter _makeRouter({String? returnTo}) => GoRouter(
  initialLocation: '/catalogos/estatus',
  routes: [
    GoRoute(
      path: '/catalogos/estatus',
      builder: (_, __) => EstatusScreen(returnTo: returnTo),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const Scaffold(body: Text('Dashboard')),
    ),
  ],
);

Widget _buildApp({List<Override> overrides = const [], String? returnTo}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: _makeRouter(returnTo: returnTo)),
  );
}

// ─────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EstatusScreen — render', () {
    testWidgets('renders "Estatus" title', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estatus'), findsOneWidget);
    });

    testWidgets('renders existing estatus items', (tester) async {
      final options = const OptionsModel(
        estatusList: ['modificado', 'nuevo', 'eliminado'],
      );
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(() => _FakeOptionsNotifier(options)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('modificado'), findsOneWidget);
      expect(find.text('nuevo'), findsOneWidget);
      expect(find.text('eliminado'), findsOneWidget);
    });

    testWidgets('renders empty state message when no estatus', (tester) async {
      final options = const OptionsModel(estatusList: []);
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(() => _FakeOptionsNotifier(options)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin estatus configurados'), findsOneWidget);
    });
  });

  group('EstatusScreen — add item', () {
    testWidgets('can type and add a new estatus item', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(const OptionsModel(estatusList: [])),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Type in the add field
      await tester.enterText(find.byType(TextField).first, 'activo');
      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('activo'), findsOneWidget);
    });
  });

  group('EstatusScreen — delete item', () {
    testWidgets('delete button removes item', (tester) async {
      final options = const OptionsModel(estatusList: ['modificado']);
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(() => _FakeOptionsNotifier(options)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('modificado'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outlined));
      await tester.pumpAndSettle();

      expect(find.text('modificado'), findsNothing);
    });
  });

  group('EstatusScreen — navigation', () {
    testWidgets('back button navigates to /dashboard by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(
              () => _FakeOptionsNotifier(OptionsModel.empty()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
