import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/api_client.dart';
import 'package:mgg_packify/models/options_model.dart';
import 'package:mgg_packify/providers/options_provider.dart';

// ─────────────────────────────────────────────
// Fake ApiClient — controls what getOptions / putOptions return
// ─────────────────────────────────────────────

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.getResult, this.putResult}) : super();

  final Future<OptionsModel> Function() getResult;
  final Future<OptionsModel> Function(OptionsModel)? putResult;

  @override
  Future<OptionsModel> getOptions() => getResult();

  @override
  Future<OptionsModel> putOptions(OptionsModel opts) {
    if (putResult != null) return putResult!(opts);
    return Future.value(opts);
  }
}

void main() {
  group('OptionsNotifier', () {
    // ── build: success path ───────────────────────

    test('build returns OptionsModel from API on success', () async {
      final expected = OptionsModel(
        estatusList: const ['nuevo', 'modificado'],
        tipoSqlList: const ['sp', 'trigger'],
        tipoBlobList: const ['css', 'js'],
      );

      final fake = _FakeApiClient(getResult: () async => expected);

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final result = await container.read(optionsProvider.future);

      expect(result.estatusList, ['nuevo', 'modificado']);
      expect(result.tipoSqlList, ['sp', 'trigger']);
      expect(result.tipoBlobList, ['css', 'js']);
    });

    // ── build: failure falls back to empty defaults ──

    test('build returns OptionsModel.empty() when API throws', () async {
      final fake = _FakeApiClient(
        getResult: () async => throw ApiException('Server down'),
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final result = await container.read(optionsProvider.future);

      // Should fall back to defaults, not throw
      expect(result.estatusList, ['modificado', 'nuevo']);
      expect(result.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(result.tipoBlobList, ['css', 'scss', 'js']);
    });

    // ── save: calls PUT and updates state ────────────

    test(
      'save calls putOptions and updates state with returned model',
      () async {
        final original = OptionsModel(
          estatusList: const ['modificado'],
          tipoSqlList: const ['sp'],
          tipoBlobList: const ['css'],
        );
        final updated = OptionsModel(
          estatusList: const ['modificado', 'nuevo'],
          tipoSqlList: const ['sp', 'trigger'],
          tipoBlobList: const ['css', 'js'],
        );

        OptionsModel? capturedPayload;

        final fake = _FakeApiClient(
          getResult: () async => original,
          putResult: (opts) async {
            capturedPayload = opts;
            return updated;
          },
        );

        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        // Let build() complete
        await container.read(optionsProvider.future);

        // Call save with a new model
        await container.read(optionsProvider.notifier).save(updated);

        // State should reflect the updated model
        final state = await container.read(optionsProvider.future);
        expect(state.estatusList, ['modificado', 'nuevo']);
        expect(state.tipoSqlList, ['sp', 'trigger']);

        // Verify the correct payload was sent to the API
        expect(capturedPayload, isNotNull);
        expect(capturedPayload!.estatusList, ['modificado', 'nuevo']);
      },
    );

    // ── save: error path sets AsyncError ──────────────

    test('save sets AsyncError when putOptions throws', () async {
      final fake = _FakeApiClient(
        getResult: () async => OptionsModel.empty(),
        putResult: (_) async =>
            throw ApiException('PUT failed', statusCode: 500),
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(optionsProvider.future);

      // save() rethrows, so we catch it here
      expect(
        () =>
            container.read(optionsProvider.notifier).save(OptionsModel.empty()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
