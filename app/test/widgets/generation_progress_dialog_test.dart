import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/models/generate_result.dart';
import 'package:mgg_packgen/widgets/generation_progress_dialog.dart';

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

/// Wraps [dialog] inside a minimal MaterialApp + Scaffold.
Widget buildDialog(Widget dialog) {
  return MaterialApp(
    home: Scaffold(body: Center(child: dialog)),
  );
}

/// Creates a [GenerateResult] that signals success.
GenerateResult _okResult({List<StepResult> steps = const []}) {
  return GenerateResult(
    ok: true,
    packageName: 'PKG',
    packageDir: '/tmp/PKG',
    docPath: '/tmp/PKG/doc.docx',
    foldersCreated: const [],
    steps: steps,
  );
}

/// Pumps the widget until the onDone callback fires.
///
/// After completing [completer], we:
/// 1. pump() → processes future microtask → _onFutureComplete runs, timer cancelled
/// 2. pump(400ms) → advances fake clock past the 300ms Future.delayed → onDone fires
Future<void> _completeAndDrain(
  WidgetTester tester,
  Completer<GenerateResult> completer,
  GenerateResult result,
) async {
  completer.complete(result);
  await tester.pump(); // process the future's .then() callback
  await tester.pump(
    const Duration(milliseconds: 400),
  ); // let delayed(300ms) fire
}

/// Same but for error path.
Future<void> _completeWithErrorAndDrain(
  WidgetTester tester,
  Completer<GenerateResult> completer,
  Object error,
) async {
  completer.completeError(error);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('GenerationProgressDialog', () {
    // ── 1. shows all step labels ──────────────────────────────────

    testWidgets('shows all step labels', (tester) async {
      final completer = Completer<GenerateResult>();

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Paso uno', 'Paso dos', 'Paso tres'],
            generateFuture: completer.future,
            onDone: (_) {},
          ),
        ),
      );

      // Initial render — all labels visible immediately
      expect(find.text('Paso uno'), findsOneWidget);
      expect(find.text('Paso dos'), findsOneWidget);
      expect(find.text('Paso tres'), findsOneWidget);

      // Clean up — complete the future to cancel the timer
      await _completeAndDrain(tester, completer, _okResult());
    });

    // ── 2. shows LinearProgressIndicator ─────────────────────────

    testWidgets('shows linear progress indicator', (tester) async {
      final completer = Completer<GenerateResult>();

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Step A', 'Step B'],
            generateFuture: completer.future,
            onDone: (_) {},
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await _completeAndDrain(tester, completer, _okResult());
    });

    // ── 3. marks step as success (done icon) after future completes ─

    testWidgets('marks steps as success when future completes ok', (
      tester,
    ) async {
      final completer = Completer<GenerateResult>();
      GenerateResult? received;

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Publicar SvcA'],
            generateFuture: completer.future,
            onDone: (r) => received = r,
          ),
        ),
      );

      // Initially: step is pending — no check_circle yet
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Complete the future with a successful result
      await _completeAndDrain(
        tester,
        completer,
        _okResult(steps: [const StepResult(label: 'Publicar SvcA', ok: true)]),
      );

      // The step should now show check_circle
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      // onDone should have been called with the result
      expect(received, isNotNull);
      expect(received!.ok, isTrue);
    });

    // ── 4. marks step as error (cancel icon) when future throws ──

    testWidgets('marks steps as error when future fails', (tester) async {
      final completer = Completer<GenerateResult>();

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Publicar SvcA'],
            generateFuture: completer.future,
            onDone: (_) {},
          ),
        ),
      );

      // Complete with an error
      await _completeWithErrorAndDrain(
        tester,
        completer,
        Exception('publish failed'),
      );

      // The step should show the cancel/error icon
      expect(find.byIcon(Icons.cancel), findsWidgets);
    });

    // ── 5. can complete even with a failed step (non-fatal) ──────

    testWidgets('calls onDone even when a step is in error state', (
      tester,
    ) async {
      final completer = Completer<GenerateResult>();
      GenerateResult? received;

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Step 1', 'Step 2'],
            generateFuture: completer.future,
            onDone: (r) => received = r,
          ),
        ),
      );

      // Simulate the future returning a result where one step failed
      await _completeAndDrain(
        tester,
        completer,
        _okResult(
          steps: [
            const StepResult(label: 'Step 1', ok: false, error: 'timeout'),
            const StepResult(label: 'Step 2', ok: true),
          ],
        ),
      );

      // onDone MUST be called regardless of step ok/error values
      expect(received, isNotNull);
    });

    // ── 6. timer advances step status over time ───────────────────

    testWidgets('timer advances first step to inProgress then done', (
      tester,
    ) async {
      final completer = Completer<GenerateResult>();

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const ['Build', 'Deploy'],
            generateFuture: completer.future,
            onDone: (_) {},
          ),
        ),
      );

      // Before first tick: first step should be pending (radio_button_unchecked)
      expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);

      // Advance past first timer tick (600ms) — first step becomes inProgress
      await tester.pump(const Duration(milliseconds: 700));

      // After one tick: first step is inProgress (CircularProgressIndicator present)
      // check_circle is NOT yet visible (no step is done)
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Advance past second tick — first step becomes done
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      // Complete future to allow widget to clean up
      await _completeAndDrain(tester, completer, _okResult());
    });

    // ── 7. renders without crashing with no steps ────────────────

    testWidgets('renders without crashing when stepLabels is empty', (
      tester,
    ) async {
      final completer = Completer<GenerateResult>();

      await tester.pumpWidget(
        buildDialog(
          GenerationProgressDialog(
            stepLabels: const [],
            generateFuture: completer.future,
            onDone: (_) {},
          ),
        ),
      );

      // Should not throw — progress shows 0/0
      expect(find.textContaining('0 / 0'), findsOneWidget);

      await _completeAndDrain(tester, completer, _okResult());
    });
  });
}
