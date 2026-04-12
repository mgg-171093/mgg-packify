import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/widgets/update_dialog.dart';

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

/// Wraps [dialog] in a MaterialApp so it can render.
Widget _buildApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

/// Builds an [UpdateDialog] that calls [onDownload] when user taps "Actualizar".
Widget _buildDialog({
  String currentVersion = '3.7.0',
  String latestVersion = '4.0.0',
  String releaseNotes = 'Bug fixes and improvements.',
  Future<void> Function({required void Function(double) onProgress})?
  onDownload,
}) {
  return _buildApp(
    UpdateDialog(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      onDownload:
          onDownload ??
          ({required onProgress}) async {
            // no-op by default
          },
    ),
  );
}

void main() {
  group('UpdateDialog', () {
    // ── Task 4.4 — smoke: renders version and release notes ─────────

    testWidgets('renders latest version and release notes', (tester) async {
      await tester.pumpWidget(_buildDialog());

      expect(find.textContaining('4.0.0'), findsWidgets);
      expect(find.text('Bug fixes and improvements.'), findsOneWidget);
    });

    testWidgets('renders current version', (tester) async {
      await tester.pumpWidget(_buildDialog());

      expect(find.textContaining('3.7.0'), findsOneWidget);
    });

    // ── Task 4.5 — "Ignorar por ahora" button present and tappable ──

    testWidgets('"Ignorar por ahora" button is present in initial state', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialog());

      expect(find.text('Ignorar por ahora'), findsOneWidget);
    });

    testWidgets('"Ignorar por ahora" button is tappable', (tester) async {
      // Dialog needs a Navigator to be dismissable, so we wrap in a full
      // MaterialApp with a dialog shown properly.
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UpdateDialog(
                      currentVersion: '3.7.0',
                      latestVersion: '4.0.0',
                      releaseNotes: '',
                      onDownload: ({required onProgress}) async {},
                    ),
                  ).then((_) => dialogClosed = true);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Ignorar por ahora'), findsOneWidget);

      // Tap "Ignorar" — should close the dialog
      await tester.tap(find.text('Ignorar por ahora'));
      await tester.pumpAndSettle();

      expect(dialogClosed, isTrue);
    });

    // ── Task 4.6 — "Actualizar ahora" triggers onDownload ───────────

    testWidgets('"Actualizar ahora" triggers onDownload callback', (
      tester,
    ) async {
      bool downloadCalled = false;
      final completer = Completer<void>();

      await tester.pumpWidget(
        _buildApp(
          UpdateDialog(
            currentVersion: '3.7.0',
            latestVersion: '4.0.0',
            releaseNotes: '',
            onDownload: ({required onProgress}) {
              downloadCalled = true;
              return completer.future;
            },
          ),
        ),
      );

      expect(find.text('Actualizar ahora'), findsOneWidget);
      await tester.tap(find.text('Actualizar ahora'));
      await tester.pump();

      expect(downloadCalled, isTrue);

      // Clean up — complete the future
      completer.complete();
      await tester.pump();
    });

    testWidgets(
      '"Actualizar ahora" is disabled while download is in progress',
      (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          _buildApp(
            UpdateDialog(
              currentVersion: '3.7.0',
              latestVersion: '4.0.0',
              releaseNotes: '',
              onDownload: ({required onProgress}) => completer.future,
            ),
          ),
        );

        // Tap "Actualizar" to start download
        await tester.tap(find.text('Actualizar ahora'));
        await tester.pump();

        // While downloading, the button should be disabled (onPressed == null)
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Actualizar ahora'),
        );
        expect(button.onPressed, isNull);

        // LinearProgressIndicator should be visible
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Clean up
        completer.complete();
        await tester.pump();
      },
    );

    // ── Task 4.7 — error state when onProgress(-1.0) is received ───

    testWidgets('shows error state when onProgress receives -1.0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          UpdateDialog(
            currentVersion: '3.7.0',
            latestVersion: '4.0.0',
            releaseNotes: '',
            onDownload: ({required onProgress}) async {
              onProgress(-1.0); // error sentinel
            },
          ),
        ),
      );

      // Trigger download
      await tester.tap(find.text('Actualizar ahora'));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.textContaining('Error al descargar'), findsOneWidget);

      // "Reintentar" button should appear
      expect(find.text('Reintentar'), findsOneWidget);

      // "Ignorar por ahora" should reappear in error state
      expect(find.text('Ignorar por ahora'), findsOneWidget);
    });

    testWidgets('shows release notes section when releaseNotes is not empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildDialog(releaseNotes: 'Fixed critical login bug.'),
      );

      expect(find.text('Fixed critical login bug.'), findsOneWidget);
    });

    testWidgets('does not show release notes section when empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialog(releaseNotes: ''));

      // Only "Nueva versión disponible" title and version lines should be present
      // No release notes text widget with empty string should be findable
      expect(find.text(''), findsNothing);
    });
  });
}
