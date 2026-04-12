import 'package:flutter/foundation.dart';
import 'component_config.dart';

// ─────────────────────────────────────────────
// ServerConfig — per-environment server addresses
// ─────────────────────────────────────────────

@immutable
class ServerConfig {
  const ServerConfig({
    this.api = '',
    this.bd = '',
    this.blob = '',
    this.liferay = '',
  });

  final String api;
  final String bd;
  final String blob;
  final String liferay;

  ServerConfig copyWith({
    String? api,
    String? bd,
    String? blob,
    String? liferay,
  }) {
    return ServerConfig(
      api: api ?? this.api,
      bd: bd ?? this.bd,
      blob: blob ?? this.blob,
      liferay: liferay ?? this.liferay,
    );
  }

  static ServerConfig empty() => const ServerConfig();

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      api: (json['api'] as String?) ?? '',
      bd: (json['bd'] as String?) ?? '',
      blob: (json['blob'] as String?) ?? '',
      liferay: (json['liferay'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'api': api,
    'bd': bd,
    'blob': blob,
    'liferay': liferay,
  };
}

// ─────────────────────────────────────────────
// PackageConfig — payload sent to POST /packages/generate
// ─────────────────────────────────────────────

@immutable
class PackageConfig {
  const PackageConfig({
    required this.ticket,
    required this.huNombre,
    required this.ambiente,
    required this.iteracion,
    required this.rutaPackages,
    required this.componentes,
    this.projectName = '',
  });

  final String ticket;
  final String huNombre;
  final String ambiente;
  final String iteracion;
  final String rutaPackages;
  final String projectName;

  /// Components in canonical order, each entry:
  /// { 'tipo': String, 'instancias': List<Map> }
  final List<Map<String, dynamic>> componentes;

  Map<String, dynamic> toJson() => {
    'ticket': ticket,
    'hu_nombre': huNombre,
    'ambiente': ambiente.toLowerCase(),
    'iteracion': iteracion.padLeft(2, '0'),
    'ruta_packages': rutaPackages,
    'componentes': componentes,
    'project_name': projectName,
  };

  factory PackageConfig.fromJson(Map<String, dynamic> json) {
    final rawComponentes = json['componentes'] as List? ?? [];
    final componentes = rawComponentes
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return PackageConfig(
      ticket: (json['ticket'] as String?) ?? '',
      huNombre: (json['hu_nombre'] as String?) ?? '',
      ambiente: (json['ambiente'] as String?) ?? 'QA',
      iteracion: (json['iteracion'] as String?) ?? '01',
      rutaPackages: (json['ruta_packages'] as String?) ?? '',
      componentes: componentes,
      projectName: (json['project_name'] as String?) ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// Helper: build componentes list from form state
// ─────────────────────────────────────────────

/// Builds the componentes list from the form's instances map,
/// in canonical order and only for selected types.
List<Map<String, dynamic>> buildComponentes(
  Set<ComponentType> selectedTypes,
  Map<ComponentType, List<ComponentInstanceState>> instances,
) {
  final result = <Map<String, dynamic>>[];
  for (final type in kCanonicalComponentOrder) {
    if (!selectedTypes.contains(type)) continue;
    final typeInstances = instances[type] ?? [];
    result.add({
      'tipo': type.key,
      'instancias': typeInstances.map((inst) => inst.toJson(type)).toList(),
    });
  }
  return result;
}
