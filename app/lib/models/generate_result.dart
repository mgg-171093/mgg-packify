import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
// StepResult — per-step publish result
// ─────────────────────────────────────────────

@immutable
class StepResult {
  const StepResult({required this.label, required this.ok, this.error = ''});

  final String label;
  final bool ok;
  final String error;

  factory StepResult.fromJson(Map<String, dynamic> json) {
    return StepResult(
      label: (json['label'] as String?) ?? '',
      ok: (json['ok'] as bool?) ?? false,
      error: (json['error'] as String?) ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// GenerateResult — API response for package generation
// ─────────────────────────────────────────────

@immutable
class GenerateResult {
  const GenerateResult({
    required this.ok,
    required this.packageName,
    required this.packageDir,
    required this.docPath,
    required this.foldersCreated,
    this.steps = const [],
    this.error,
    this.copyErrors = const [],
  });

  final bool ok;
  final String packageName;
  final String packageDir;
  final String docPath;
  final List<String> foldersCreated;
  final List<StepResult> steps;
  final String? error;
  final List<String> copyErrors;

  factory GenerateResult.fromJson(Map<String, dynamic> json) {
    return GenerateResult(
      ok: (json['ok'] as bool?) ?? false,
      packageName: (json['package_name'] as String?) ?? '',
      packageDir: (json['package_dir'] as String?) ?? '',
      docPath: (json['doc_path'] as String?) ?? '',
      foldersCreated:
          (json['folders_created'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      steps:
          (json['steps'] as List?)
              ?.map((e) => StepResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      error: json['error'] as String?,
      copyErrors: (json['copy_errors'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  GenerateResult copyWith({
    bool? ok,
    String? packageName,
    String? packageDir,
    String? docPath,
    List<String>? foldersCreated,
    List<StepResult>? steps,
    String? error,
    List<String>? copyErrors,
  }) {
    return GenerateResult(
      ok: ok ?? this.ok,
      packageName: packageName ?? this.packageName,
      packageDir: packageDir ?? this.packageDir,
      docPath: docPath ?? this.docPath,
      foldersCreated: foldersCreated ?? this.foldersCreated,
      steps: steps ?? this.steps,
      error: error ?? this.error,
      copyErrors: copyErrors ?? this.copyErrors,
    );
  }

  factory GenerateResult.error(String message) {
    return GenerateResult(
      ok: false,
      packageName: '',
      packageDir: '',
      docPath: '',
      foldersCreated: const [],
      error: message,
    );
  }
}
