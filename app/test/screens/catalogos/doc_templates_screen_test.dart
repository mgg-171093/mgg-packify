import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/providers/options_provider.dart';
import 'package:mgg_packify/screens/catalogos/doc_templates_screen.dart';
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

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/catalogos/doc-templates',
  routes: [
    GoRoute(
      path: '/catalogos/doc-templates',
      builder: (_, __) => const DocTemplatesScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const Scaffold(body: Text('Dashboard')),
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

  group('DocTemplatesScreen — render', () {
    testWidgets('renders TabBar with correct tab labels', (tester) async {
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

      // The TabBar should be present
      expect(find.byType(TabBar), findsOneWidget);

      // Verify a few tab labels are present (use findsAtLeastNWidgets because
      // the first tab label also appears in the section header)
      expect(find.text('General'), findsAtLeastNWidgets(1));
      expect(find.text('SQL'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders AppBar title', (tester) async {
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

      expect(find.text('Texto de Documentos'), findsOneWidget);
    });

    testWidgets('renders all 9 tabs', (tester) async {
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

      // Tab labels are scrollable — use findsAtLeastNWidgets since the
      // first tab's text also appears in the content area section header.
      expect(find.text('General'), findsAtLeastNWidgets(1));
      expect(find.text('SQL'), findsAtLeastNWidgets(1));
      expect(find.text('API IIS'), findsOneWidget);
      expect(find.text('API Docker'), findsOneWidget);
      expect(find.text('Blob Storage'), findsOneWidget);
      expect(find.text('Liferay Build'), findsOneWidget);
      expect(find.text('Liferay'), findsAtLeastNWidgets(1));
      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('APIM'), findsOneWidget);
    });

    testWidgets('General tab shows template fields with hint text', (
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

      // The first tab (General) should be shown by default
      // It should have TextFields with the default hint texts
      expect(find.byType(TextField), findsWidgets);

      // The 'title' field hint should show the default text
      expect(find.text('Manual de instalación'), findsOneWidget);
    });

    testWidgets('shows overridden value in text field', (tester) async {
      final options = OptionsModel(
        docTemplates: const {
          'doc': {'title': 'Mi título personalizado'},
        },
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(() => _FakeOptionsNotifier(options)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi título personalizado'), findsOneWidget);
    });

    testWidgets('shows "Restablecer todo" button when section has overrides', (
      tester,
    ) async {
      final options = OptionsModel(
        docTemplates: const {
          'doc': {'title': 'Personalizado'},
        },
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            optionsProvider.overrideWith(() => _FakeOptionsNotifier(options)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restablecer todo'), findsOneWidget);
    });

    testWidgets('does not show "Restablecer todo" when no overrides', (
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

      expect(find.text('Restablecer todo'), findsNothing);
    });
  });

  group('DocTemplatesScreen — navigation', () {
    testWidgets('back button navigates to /dashboard', (tester) async {
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
