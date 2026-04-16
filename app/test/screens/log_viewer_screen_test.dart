import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/api_client.dart';
import 'package:mgg_packify/screens/log_viewer_screen.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.appLines, required this.apiLines}) : super();

  final List<String> appLines;
  final List<String> apiLines;

  @override
  Future<Map<String, dynamic>> getLogs({
    String source = 'app',
    int lines = 200,
  }) async {
    if (source == 'app') {
      return {'lines': appLines};
    }
    return {'lines': apiLines};
  }
}

void main() {
  Widget buildApp(ApiClient client) {
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client)],
      child: const MaterialApp(home: LogViewerScreen()),
    );
  }

  testWidgets('empty log state uses semantic icon color emphasis', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(_FakeApiClient(appLines: const [], apiLines: const [])),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.article_outlined).first);
    final theme = Theme.of(tester.element(find.byType(LogViewerScreen)));
    expect(icon.color, theme.colorScheme.primary);
    expect(find.text('Sin logs disponibles'), findsOneWidget);
    expect(
      find.text('Cuando haya actividad, vas a verla acá.'),
      findsOneWidget,
    );
  });
}
