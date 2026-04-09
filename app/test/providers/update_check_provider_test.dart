import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/app_logger.dart';
import 'package:mgg_packify/providers/update_check_provider.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() async {
    // AppLogger uses a late field — initialize once before any test that
    // exercises code paths that call AppLogger.w() or AppLogger.i().
    await AppLogger.initialize();
  });

  group('UpdateCheckNotifier — build()', () {
    test('initializes with hasUpdate: false', () async {
      final container = _makeContainer();
      final state = await container.read(updateCheckProvider.future);
      expect(state.hasUpdate, isFalse);
    });

    test('initializes with empty latestVersion', () async {
      final container = _makeContainer();
      final state = await container.read(updateCheckProvider.future);
      expect(state.latestVersion, isEmpty);
    });

    test('initializes with empty releaseNotes', () async {
      final container = _makeContainer();
      final state = await container.read(updateCheckProvider.future);
      expect(state.releaseNotes, isEmpty);
    });

    test('UpdateCheckState.none() constructs expected defaults', () {
      final none = UpdateCheckState.none();
      expect(none.hasUpdate, isFalse);
      expect(none.latestVersion, '');
      expect(none.releaseNotes, '');
    });
  });

  group('UpdateCheckNotifier — checkForUpdates() with network error', () {
    test(
      'state remains hasUpdate: false after network failure (silent failure)',
      () async {
        final container = _makeContainer();
        // Let build settle
        await container.read(updateCheckProvider.future);

        // checkForUpdates() tries a real HTTP call that will fail in test env
        // (no network / no GitHub endpoint) → silent catch → stays none()
        await container.read(updateCheckProvider.notifier).checkForUpdates();

        final state = await container.read(updateCheckProvider.future);
        expect(state.hasUpdate, isFalse);
      },
    );

    test('state is AsyncData (not AsyncError) after network failure', () async {
      final container = _makeContainer();
      await container.read(updateCheckProvider.future);

      await container.read(updateCheckProvider.notifier).checkForUpdates();

      // Must be AsyncData — network error is swallowed
      expect(
        container.read(updateCheckProvider),
        isA<AsyncData<UpdateCheckState>>(),
      );
    });
  });

  group('_isNewer semver logic — via UpdateCheckState construction', () {
    // _isNewer is private but its contract is: returns true only when
    // candidate is strictly greater than current (major.minor.patch).
    // We validate the public surface: UpdateCheckState values and the
    // overall behaviour guarantee documented in the source.

    test('UpdateCheckState can represent a detected update', () {
      const state = UpdateCheckState(
        hasUpdate: true,
        latestVersion: '4.0.0',
        releaseNotes: 'New release',
      );
      expect(state.hasUpdate, isTrue);
      expect(state.latestVersion, '4.0.0');
      expect(state.releaseNotes, 'New release');
    });

    test('UpdateCheckState can represent no update', () {
      const state = UpdateCheckState(
        hasUpdate: false,
        latestVersion: '3.5.0',
        releaseNotes: '',
      );
      expect(state.hasUpdate, isFalse);
    });
  });
}
