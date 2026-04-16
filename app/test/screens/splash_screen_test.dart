import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/api_client.dart';
import 'package:mgg_packify/core/server_manager.dart';
import 'package:mgg_packify/screens/splash_screen.dart';

class _FakeServerManager extends ServerManager {
  @override
  Future<void> start() => Completer<void>().future;
}

class _FailingApiClient extends ApiClient {
  _FailingApiClient() : super();

  @override
  Future<void> getHealth() async {
    throw const ApiException('not ready');
  }
}

void main() {
  testWidgets('starting state uses semantic primary progress color', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverManagerProvider.overrideWithValue(_FakeServerManager()),
          apiClientProvider.overrideWithValue(_FailingApiClient()),
        ],
        child: const MaterialApp(
          home: SplashScreen(minDisplayDuration: Duration.zero),
        ),
      ),
    );
    await tester.pump();

    final theme = Theme.of(tester.element(find.byType(SplashScreen)));
    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );

    expect(progress.color, theme.colorScheme.primary);
    expect(find.text('Iniciando servidor...'), findsOneWidget);
  });
}
