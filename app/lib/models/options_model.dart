import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
// ApiIisServiceEntry — catalog entry for IIS APIs
// ─────────────────────────────────────────────

@immutable
class ApiIisServiceEntry {
  const ApiIisServiceEntry({required this.nombre, required this.ruta});

  final String nombre;
  final String ruta;

  ApiIisServiceEntry copyWith({String? nombre, String? ruta}) {
    return ApiIisServiceEntry(
      nombre: nombre ?? this.nombre,
      ruta: ruta ?? this.ruta,
    );
  }

  factory ApiIisServiceEntry.fromJson(Map<String, dynamic> json) {
    return ApiIisServiceEntry(
      nombre: (json['nombre'] as String?) ?? '',
      ruta: (json['ruta'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'nombre': nombre, 'ruta': ruta};
}

// ─────────────────────────────────────────────
// ApiDockerServiceEntry — catalog entry for Docker APIs
// ─────────────────────────────────────────────

@immutable
class ApiDockerServiceEntry {
  const ApiDockerServiceEntry({required this.nombre});

  final String nombre;

  ApiDockerServiceEntry copyWith({String? nombre}) {
    return ApiDockerServiceEntry(nombre: nombre ?? this.nombre);
  }

  factory ApiDockerServiceEntry.fromJson(Map<String, dynamic> json) {
    return ApiDockerServiceEntry(nombre: (json['nombre'] as String?) ?? '');
  }

  Map<String, dynamic> toJson() => {'nombre': nombre};
}

// ─────────────────────────────────────────────
// OptionsModel — configurable option lists
// ─────────────────────────────────────────────

@immutable
class OptionsModel {
  const OptionsModel({
    this.estatusList = const ['modificado', 'nuevo'],
    this.tipoSqlList = const ['sp', 'trigger', 'script', 'job'],
    this.tipoBlobList = const ['css', 'scss', 'js'],
    this.apiIisServices = const [],
    this.apiDockerServices = const [],
    this.sqlDatabases = const [],
    this.docTemplates = const {},
  });

  final List<String> estatusList;
  final List<String> tipoSqlList;
  final List<String> tipoBlobList;
  final List<ApiIisServiceEntry> apiIisServices;
  final List<ApiDockerServiceEntry> apiDockerServices;
  final List<String> sqlDatabases;

  /// User overrides for doc template text, keyed by section then field name.
  /// Null values mean "use default Python text"; non-null = user override.
  final Map<String, Map<String, String?>> docTemplates;

  OptionsModel copyWith({
    List<String>? estatusList,
    List<String>? tipoSqlList,
    List<String>? tipoBlobList,
    List<ApiIisServiceEntry>? apiIisServices,
    List<ApiDockerServiceEntry>? apiDockerServices,
    List<String>? sqlDatabases,
    Map<String, Map<String, String?>>? docTemplates,
  }) {
    return OptionsModel(
      estatusList: estatusList ?? this.estatusList,
      tipoSqlList: tipoSqlList ?? this.tipoSqlList,
      tipoBlobList: tipoBlobList ?? this.tipoBlobList,
      apiIisServices: apiIisServices ?? this.apiIisServices,
      apiDockerServices: apiDockerServices ?? this.apiDockerServices,
      sqlDatabases: sqlDatabases ?? this.sqlDatabases,
      docTemplates: docTemplates ?? this.docTemplates,
    );
  }

  static OptionsModel empty() => const OptionsModel();

  factory OptionsModel.fromJson(Map<String, dynamic> json) {
    // Parse doc_templates: Map<String, Map<String, String?>>
    // Null values from JSON are preserved as null in the inner map.
    final rawTemplates = json['doc_templates'] as Map<String, dynamic>?;
    final docTemplates = <String, Map<String, String?>>{};
    if (rawTemplates != null) {
      for (final entry in rawTemplates.entries) {
        final inner = entry.value as Map<String, dynamic>?;
        if (inner != null) {
          docTemplates[entry.key] = inner.map(
            (k, v) => MapEntry(k, v as String?),
          );
        }
      }
    }

    return OptionsModel(
      estatusList:
          (json['estatus_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['modificado', 'nuevo'],
      tipoSqlList:
          (json['tipo_sql_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['sp', 'trigger', 'script', 'job'],
      tipoBlobList:
          (json['tipo_blob_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['css', 'scss', 'js'],
      apiIisServices:
          (json['api_iis_services'] as List?)
              ?.map(
                (e) => ApiIisServiceEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      apiDockerServices:
          (json['api_docker_services'] as List?)
              ?.map(
                (e) =>
                    ApiDockerServiceEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      sqlDatabases: (json['sql_databases'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      docTemplates: docTemplates,
    );
  }

  Map<String, dynamic> toJson() => {
    'estatus_options': estatusList,
    'tipo_sql_options': tipoSqlList,
    'tipo_blob_options': tipoBlobList,
    'api_iis_services': apiIisServices.map((e) => e.toJson()).toList(),
    'api_docker_services': apiDockerServices.map((e) => e.toJson()).toList(),
    'sql_databases': sqlDatabases,
    'doc_templates': docTemplates,
  };
}
