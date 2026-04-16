import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/package_template.dart';
import 'package:mgg_packify/providers/templates_provider.dart';
import 'package:mgg_packify/screens/templates_screen.dart';

class _FakeTemplatesNotifier extends AsyncNotifier<List<PackageTemplate>>
    implements TemplatesNotifier {
  _FakeTemplatesNotifier(this._templates);
  final List<PackageTemplate> _templates;

  @override
  Future<List<PackageTemplate>> build() async => _templates;

  @override
  Future<void> save(PackageTemplate template) async {}

  @override
  Future<void> delete(int index) async {}
}

void main() {
  testWidgets('empty state icon uses semantic primary color', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templatesProvider.overrideWith(
            () => _FakeTemplatesNotifier(const []),
          ),
        ],
        child: const MaterialApp(home: TemplatesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark_border));
    final theme = Theme.of(tester.element(find.byType(TemplatesScreen)));

    expect(icon.color, theme.colorScheme.primary);
    expect(find.text('No hay templates guardados'), findsOneWidget);
  });
}
