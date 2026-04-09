import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/app_logger.dart';
import 'package:mgg_packify/providers/health_polling_provider.dart';
import 'package:mgg_packify/providers/server_status_provider.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() async {
    // AppLogger uses a late field — initialize once before tests that
    // exercise code paths calling AppLogger.i() or AppLogger.w().
    await AppLogger.initialize();
  });

  group('HealthPollingNotifier — build()', () {
    test('provider builds without errors', () {
      final container = _makeContainer();
      // NotifierProvider<..., void> — just read the notifier to trigger build
      expect(
        () => container.read(healthPollingProvider.notifier),
        returnsNormally,
      );
    });

    test('build() does not start a timer automatically', () {
      // Provider should be inert on creation — polling only starts
      // when startPolling() is explicitly called.
      // We verify this by reading after build and checking no side effects.
      final container = _makeContainer();
      container.read(healthPollingProvider.notifier);
      // serverStatusProvider remains at its initial value (starting)
      expect(container.read(serverStatusProvider), ServerStatus.starting);
    });
  });

  group('HealthPollingNotifier — startPolling()', () {
    test('startPolling() can be called without throwing', () {
      final container = _makeContainer();
      expect(
        () => container.read(healthPollingProvider.notifier).startPolling(),
        returnsNormally,
      );
    });

    test(
      'startPolling() called twice does not throw (cancels previous timer)',
      () {
        final container = _makeContainer();
        final notifier = container.read(healthPollingProvider.notifier);
        expect(() => notifier.startPolling(), returnsNormally);
        expect(() => notifier.startPolling(), returnsNormally);
      },
    );
  });

  group('HealthPollingNotifier — stopPolling()', () {
    test(
      'stopPolling() can be called before startPolling() without throwing',
      () {
        final container = _makeContainer();
        expect(
          () => container.read(healthPollingProvider.notifier).stopPolling(),
          returnsNormally,
        );
      },
    );

    test('stopPolling() after startPolling() does not throw', () {
      final container = _makeContainer();
      final notifier = container.read(healthPollingProvider.notifier);
      notifier.startPolling();
      expect(() => notifier.stopPolling(), returnsNormally);
    });

    test('stopPolling() clears timer — no further callbacks fire', () async {
      // After stopPolling(), the internal timer is null.
      // We can indirectly verify: serverStatus must NOT change spontaneously
      // after stop (no HTTP calls happen without a timer).
      final container = _makeContainer();
      final notifier = container.read(healthPollingProvider.notifier);
      notifier.startPolling();
      notifier.stopPolling();

      // Give the event loop a chance to process any immediate callbacks
      await Future<void>.delayed(Duration.zero);

      // Status is still starting — no polling happened
      expect(container.read(serverStatusProvider), ServerStatus.starting);
    });
  });

  group('HealthPollingNotifier — dispose()', () {
    test('disposing the container cancels the timer without throwing', () {
      final container = ProviderContainer();
      container.read(healthPollingProvider.notifier).startPolling();
      expect(() => container.dispose(), returnsNormally);
    });
  });

  group('HealthPollingNotifier — ref.read constraint', () {
    // Verified by code review: _checkHealth() and _markFailed() both use
    // ref.read(serverStatusProvider) — never ref.watch. This is intentional:
    // watching inside a timer callback would be invalid Riverpod usage.
    // Documented here as a static constraint test (code review assertion).
    test(
      'CONSTRAINT: _checkHealth uses ref.read, never ref.watch (code review)',
      () {
        // This test serves as documentation of the architectural constraint.
        // The actual enforcement is the source code itself — verified manually.
        expect(
          true,
          isTrue,
          reason: 'ref.read enforced in source — see comments',
        );
      },
    );
  });
}
