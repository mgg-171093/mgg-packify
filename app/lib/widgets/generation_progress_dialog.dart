import 'dart:async';
import 'package:flutter/material.dart';
import '../models/generate_result.dart';

// ─────────────────────────────────────────────
// StepStatus
// ─────────────────────────────────────────────

enum StepStatus { pending, inProgress, done, error }

// ─────────────────────────────────────────────
// GenerationStep — mutable step model
// ─────────────────────────────────────────────

class GenerationStep {
  GenerationStep({
    required this.label,
    this.status = StepStatus.pending,
    this.errorMessage,
  });

  final String label;
  StepStatus status;
  String? errorMessage;
}

// ─────────────────────────────────────────────
// GenerationProgressDialog
// ─────────────────────────────────────────────

class GenerationProgressDialog extends StatefulWidget {
  const GenerationProgressDialog({
    super.key,
    required this.stepLabels,
    required this.generateFuture,
    required this.onDone,
  });

  final List<String> stepLabels;
  final Future<GenerateResult> generateFuture;
  final void Function(GenerateResult) onDone;

  @override
  State<GenerationProgressDialog> createState() =>
      _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<GenerationProgressDialog> {
  late List<GenerationStep> _steps;
  Timer? _timer;
  bool _futureCompleted = false;

  @override
  void initState() {
    super.initState();

    _steps = widget.stepLabels
        .map((label) => GenerationStep(label: label))
        .toList();

    // Start timer to optimistically advance steps
    _timer = Timer.periodic(const Duration(milliseconds: 600), _onTick);

    // Listen to the generate future
    widget.generateFuture
        .then((result) {
          _onFutureComplete(result, null);
        })
        .catchError((Object error) {
          _onFutureComplete(null, error);
        });
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() {
      // Find first inProgress step and mark it done
      final inProgressIdx = _steps.indexWhere(
        (s) => s.status == StepStatus.inProgress,
      );
      if (inProgressIdx != -1) {
        _steps[inProgressIdx].status = StepStatus.done;
      }
      // Advance first pending step to inProgress
      final pendingIdx = _steps.indexWhere(
        (s) => s.status == StepStatus.pending,
      );
      if (pendingIdx != -1) {
        _steps[pendingIdx].status = StepStatus.inProgress;
      }
    });
  }

  void _onFutureComplete(GenerateResult? result, Object? error) {
    if (!mounted) return;
    _timer?.cancel();
    _timer = null;

    setState(() {
      if (error != null) {
        // Mark all remaining pending/inProgress steps as error
        for (final step in _steps) {
          if (step.status == StepStatus.pending ||
              step.status == StepStatus.inProgress) {
            step.status = StepStatus.error;
            step.errorMessage = error.toString();
          }
        }
      } else {
        // Mark all remaining pending/inProgress steps as done
        for (final step in _steps) {
          if (step.status == StepStatus.pending ||
              step.status == StepStatus.inProgress) {
            step.status = StepStatus.done;
          }
        }
      }
      _futureCompleted = true;
    });

    // Wait 300ms then call onDone
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final finalResult =
            result ??
            GenerateResult.error(error?.toString() ?? 'Error desconocido');
        widget.onDone(finalResult);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _completedCount => _steps
      .where((s) => s.status == StepStatus.done || s.status == StepStatus.error)
      .length;

  int get _totalCount => _steps.length;

  @override
  Widget build(BuildContext context) {
    final completed = _completedCount;
    final total = _totalCount;
    final progress = total > 0 ? completed / total : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 420, maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ──
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generando package...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Steps list ──
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      _buildStepRow(_steps[i], colorScheme),
                      if (i < _steps.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.surfaceContainerHighest,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Progress bar ──
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),

              // ── Progress text ──
              Text(
                '$completed / $total pasos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(GenerationStep step, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          SizedBox(
            width: 24,
            height: 24,
            child: _buildStepIcon(step.status, colorScheme),
          ),
          const SizedBox(width: 12),
          // Label + error message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: switch (step.status) {
                      StepStatus.pending => colorScheme.onSurfaceVariant,
                      StepStatus.inProgress => colorScheme.onSurface,
                      StepStatus.done => colorScheme.onSurface,
                      StepStatus.error => colorScheme.error,
                    },
                    fontSize: 14,
                  ),
                ),
                if (step.status == StepStatus.error &&
                    step.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.errorMessage!,
                    style: TextStyle(color: colorScheme.error, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(StepStatus status, ColorScheme colorScheme) {
    return switch (status) {
      StepStatus.pending => Icon(
        Icons.radio_button_unchecked,
        color: colorScheme.outline,
        size: 20,
      ),
      StepStatus.inProgress => CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
      StepStatus.done => Icon(
        Icons.check_circle,
        color: colorScheme.primary,
        size: 20,
      ),
      StepStatus.error => Icon(
        Icons.cancel,
        color: colorScheme.error,
        size: 20,
      ),
    };
  }
}
