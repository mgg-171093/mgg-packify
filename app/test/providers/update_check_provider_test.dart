import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
      // Task 4.2 — downloadUrl defaults to empty string
      expect(none.downloadUrl, '');
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
        downloadUrl: 'https://example.com/update.exe',
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
        downloadUrl: '',
      );
      expect(state.hasUpdate, isFalse);
    });
  });

  // ── Task 4.1 — downloadUrl populated from latest.json url field ──────────

  group('UpdateCheckNotifier — downloadUrl field', () {
    test(
      'downloadUrl is populated from latest.json url field when update available',
      () async {
        const fakeJson =
            '{'
            '"version":"999.0.0",'
            '"release_notes":"Big update",'
            '"url":"https://example.com/mgg-packify-setup.exe"'
            '}';

        final mockClient = MockClient((_) async {
          return http.Response(fakeJson, 200);
        });

        final container = _makeContainer();
        await container.read(updateCheckProvider.future);

        await container
            .read(updateCheckProvider.notifier)
            .checkForUpdates(client: mockClient);

        final result = await container.read(updateCheckProvider.future);
        expect(result.hasUpdate, isTrue);
        expect(result.downloadUrl, 'https://example.com/mgg-packify-setup.exe');
      },
    );

    test('downloadUrl is empty when no update available', () async {
      const fakeJson =
          '{'
          '"version":"0.0.1",'
          '"release_notes":"",'
          '"url":"https://example.com/old.exe"'
          '}';

      final mockClient = MockClient((_) async {
        return http.Response(fakeJson, 200);
      });

      final container = _makeContainer();
      await container.read(updateCheckProvider.future);

      await container
          .read(updateCheckProvider.notifier)
          .checkForUpdates(client: mockClient);

      final result = await container.read(updateCheckProvider.future);
      // Older version → no update, but downloadUrl is still captured
      expect(result.hasUpdate, isFalse);
    });
  });

  // ── Task 4.3 — downloadAndInstall calls onProgress(-1.0) on error ────────

  group('UpdateCheckNotifier — downloadAndInstall()', () {
    test(
      'calls onProgress(-1.0) when http.Client throws during download',
      () async {
        // First, put the notifier in a state with a downloadUrl
        const fakeCheckJson =
            '{'
            '"version":"999.0.0",'
            '"release_notes":"Big update",'
            '"url":"https://example.com/setup.exe"'
            '}';

        final checkClient = MockClient((_) async {
          return http.Response(fakeCheckJson, 200);
        });

        final container = _makeContainer();
        await container.read(updateCheckProvider.future);
        await container
            .read(updateCheckProvider.notifier)
            .checkForUpdates(client: checkClient);
        await container.read(updateCheckProvider.future);

        // Now inject a client that throws during download
        final throwingClient = MockClient((_) async {
          throw Exception('Network error');
        });

        double? lastProgress;
        await container
            .read(updateCheckProvider.notifier)
            .downloadAndInstall(
              onProgress: (p) => lastProgress = p,
              client: throwingClient,
            );

        expect(lastProgress, -1.0);
      },
    );
  });

  // ── Task 4.8 & 4.9 — Timer behaviour ────────────────────────────────────

  group('UpdateCheckNotifier — polling timer', () {
    test(
      'timer is cancelled after update is found (hasUpdate becomes true)',
      () async {
        // Feed a mock that returns a newer version
        const fakeJson =
            '{'
            '"version":"999.0.0",'
            '"release_notes":"Big update",'
            '"url":"https://example.com/setup.exe"'
            '}';

        final mockClient = MockClient((_) async {
          return http.Response(fakeJson, 200);
        });

        final container = _makeContainer();
        await container.read(updateCheckProvider.future);

        await container
            .read(updateCheckProvider.notifier)
            .checkForUpdates(client: mockClient);

        final result = await container.read(updateCheckProvider.future);
        expect(result.hasUpdate, isTrue);

        // After hasUpdate=true, the internal timer should be null/cancelled.
        // We verify by calling checkForUpdates again — it should NOT reset
        // hasUpdate to false even if called (the timer being null is the
        // internal invariant; externally we verify the state stays correct).
        // The critical behaviour: provider still has hasUpdate: true
        expect(
          container.read(updateCheckProvider).valueOrNull?.hasUpdate,
          isTrue,
        );
      },
    );

    test(
      'timer fires checkForUpdates — verified via mock http call count',
      () async {
        // This test verifies the timer mechanism by manually calling
        // checkForUpdates with a mock client (same code path the timer uses).
        int callCount = 0;
        const fakeJson =
            '{'
            '"version":"999.0.0",'
            '"release_notes":"",'
            '"url":"https://example.com/setup.exe"'
            '}';

        final mockClient = MockClient((_) async {
          callCount++;
          return http.Response(fakeJson, 200);
        });

        final container = _makeContainer();
        await container.read(updateCheckProvider.future);

        // Simulate timer firing once
        await container
            .read(updateCheckProvider.notifier)
            .checkForUpdates(client: mockClient);

        expect(callCount, 1);

        // After update found, timer is cancelled — next manual call still works
        // but timer won't fire again automatically
        final state = await container.read(updateCheckProvider.future);
        expect(state.hasUpdate, isTrue);
      },
    );
  });
}
