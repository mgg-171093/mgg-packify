import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
// ComponentType enum
// ─────────────────────────────────────────────

enum ComponentType {
  liferayBuild('liferay_build', 'Liferay (Deploy de build)', false),
  sql('sql', 'SQL', true),
  apiIis('api_iis', 'API IIS (.zip)', true),
  apiDocker('api_docker', 'API Docker / Pipeline CI-CD', true),
  blob('blob', 'Blob Storage (JS/CSS)', true),
  liferay('liferay', 'Liferay (Remote App / Página)', true),
  assets('assets', 'Assets (imágenes Liferay)', true),
  apim('apim', 'Azure API Management', true);

  const ComponentType(this.key, this.label, this.isMultiInstance);
  final String key;
  final String label;
  final bool isMultiInstance;

  static ComponentType fromKey(String key) {
    return ComponentType.values.firstWhere((e) => e.key == key);
  }
}

/// Canonical render order — always use this list for UI ordering
const kCanonicalComponentOrder = [
  ComponentType.liferayBuild,
  ComponentType.sql,
  ComponentType.apiIis,
  ComponentType.apiDocker,
  ComponentType.blob,
  ComponentType.liferay,
  ComponentType.assets,
  ComponentType.apim,
];

// ─────────────────────────────────────────────
// ConfigEntry — key/value pair for api config
// ─────────────────────────────────────────────

@immutable
class ConfigEntry {
  const ConfigEntry({
    required this.clave,
    required this.valor,
    this.imagenPath,
  });

  final String clave;
  final String valor;
  final String? imagenPath;

  ConfigEntry copyWith({String? clave, String? valor, String? imagenPath}) {
    return ConfigEntry(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }

  factory ConfigEntry.fromJson(Map<String, dynamic> json) {
    return ConfigEntry(
      clave: (json['clave'] as String?) ?? '',
      valor: (json['valor'] as String?) ?? '',
      imagenPath: json['imagen_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'clave': clave,
    'valor': valor,
    if (imagenPath != null) 'imagen_path': imagenPath,
  };

  static ConfigEntry empty() => const ConfigEntry(clave: '', valor: '');
}

// ─────────────────────────────────────────────
// FileEntry — file name + folder for blob
// ─────────────────────────────────────────────

@immutable
class FileEntry {
  const FileEntry({required this.nombre, required this.carpeta});

  final String nombre;
  final String carpeta;

  FileEntry copyWith({String? nombre, String? carpeta}) {
    return FileEntry(
      nombre: nombre ?? this.nombre,
      carpeta: carpeta ?? this.carpeta,
    );
  }

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      nombre: (json['nombre'] as String?) ?? '',
      carpeta: (json['carpeta'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'nombre': nombre, 'carpeta': carpeta};

  static FileEntry empty() => const FileEntry(nombre: '', carpeta: '');
}

// ─────────────────────────────────────────────
// ComponentInstanceState
// ─────────────────────────────────────────────

@immutable
class ComponentInstanceState {
  const ComponentInstanceState({
    this.buildId = '',
    this.baseDatos = '',
    this.scripts = const [],
    this.scriptsCopiar = const [],
    this.nombreServicio = '',
    this.configs = const [],
    this.archivos = const [],
    this.nombre = '',
    this.esNueva = false,
    this.crearPagina = false,
    this.pagina = '',
    this.widgets = const [],
    this.estatus = 'modificado',
    this.tipo = '',
    this.publicar = false,
  });

  // liferay_build
  final String buildId;
  // sql
  final String baseDatos;
  final List<String> scripts;

  /// Parallel to [scripts] — whether each script should be copied manually.
  final List<bool> scriptsCopiar;
  // api_iis, api_docker, apim
  final String nombreServicio;
  final List<ConfigEntry> configs;
  // blob
  final List<FileEntry> archivos;
  // liferay
  final String nombre;
  final bool esNueva;
  final bool crearPagina;
  final String pagina;
  final List<String> widgets;
  // common — all types
  final String estatus;
  final String tipo;
  // api_iis — publish flag
  final bool publicar;

  ComponentInstanceState copyWith({
    String? buildId,
    String? baseDatos,
    List<String>? scripts,
    List<bool>? scriptsCopiar,
    String? nombreServicio,
    List<ConfigEntry>? configs,
    List<FileEntry>? archivos,
    String? nombre,
    bool? esNueva,
    bool? crearPagina,
    String? pagina,
    List<String>? widgets,
    String? estatus,
    String? tipo,
    bool? publicar,
  }) {
    return ComponentInstanceState(
      buildId: buildId ?? this.buildId,
      baseDatos: baseDatos ?? this.baseDatos,
      scripts: scripts ?? this.scripts,
      scriptsCopiar: scriptsCopiar ?? this.scriptsCopiar,
      nombreServicio: nombreServicio ?? this.nombreServicio,
      configs: configs ?? this.configs,
      archivos: archivos ?? this.archivos,
      nombre: nombre ?? this.nombre,
      esNueva: esNueva ?? this.esNueva,
      crearPagina: crearPagina ?? this.crearPagina,
      pagina: pagina ?? this.pagina,
      widgets: widgets ?? this.widgets,
      estatus: estatus ?? this.estatus,
      tipo: tipo ?? this.tipo,
      publicar: publicar ?? this.publicar,
    );
  }

  static ComponentInstanceState empty() => const ComponentInstanceState();

  /// Returns only the fields relevant to the given [type].
  Map<String, dynamic> toJson(ComponentType type) {
    return switch (type) {
      ComponentType.liferayBuild => {
        'build_id': buildId,
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.sql => {
        'base_datos': baseDatos,
        'scripts': scripts,
        'scripts_copiar': scriptsCopiar,
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.apiIis => {
        'nombre_servicio': nombreServicio,
        'configs': configs.map((c) => c.toJson()).toList(),
        'estatus': estatus,
        'tipo': tipo,
        'publicar': publicar,
      },
      ComponentType.apiDocker => {
        'nombre_servicio': nombreServicio,
        'configs': configs.map((c) => c.toJson()).toList(),
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.blob => {
        'archivos': archivos.map((f) => f.toJson()).toList(),
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.liferay => {
        'nombre': nombre,
        'es_nueva': esNueva,
        'crear_pagina': crearPagina,
        if (crearPagina) 'pagina': pagina,
        if (crearPagina) 'widgets': widgets,
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.assets => {
        'nombre': nombre,
        'estatus': estatus,
        'tipo': tipo,
      },
      ComponentType.apim => {
        'nombre_servicio': nombreServicio,
        'estatus': estatus,
        'tipo': tipo,
      },
    };
  }

  /// Build from JSON prefill data (clone response)
  factory ComponentInstanceState.fromJson(Map<String, dynamic> json) {
    final scripts =
        (json['scripts'] as List?)?.map((e) => e.toString()).toList() ?? [];
    // Parse scripts_copiar and pad/truncate to match scripts length
    final rawCopiar =
        (json['scripts_copiar'] as List?)?.map((e) => e as bool).toList() ??
        <bool>[];
    final scriptsCopiar = List<bool>.from(rawCopiar);
    while (scriptsCopiar.length < scripts.length) {
      scriptsCopiar.add(false);
    }
    while (scriptsCopiar.length > scripts.length) {
      scriptsCopiar.removeLast();
    }
    return ComponentInstanceState(
      buildId: (json['build_id'] as String?) ?? '',
      baseDatos: (json['base_datos'] as String?) ?? '',
      scripts: scripts,
      scriptsCopiar: scriptsCopiar,
      nombreServicio: (json['nombre_servicio'] as String?) ?? '',
      configs:
          (json['configs'] as List?)
              ?.map((e) => ConfigEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      archivos:
          (json['archivos'] as List?)
              ?.map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nombre: (json['nombre'] as String?) ?? '',
      esNueva: (json['es_nueva'] as bool?) ?? false,
      crearPagina: (json['crear_pagina'] as bool?) ?? false,
      pagina: (json['pagina'] as String?) ?? '',
      widgets:
          (json['widgets'] as List?)?.map((e) => e.toString()).toList() ?? [],
      estatus: (json['estatus'] as String?) ?? 'modificado',
      tipo: (json['tipo'] as String?) ?? '',
      publicar: (json['publicar'] as bool?) ?? false,
    );
  }
}
