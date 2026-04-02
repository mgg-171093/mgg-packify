import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
// ServerConfigModel — matches API settings schema
// ─────────────────────────────────────────────

@immutable
class ServerConfigModel {
  const ServerConfigModel({
    this.api = '',
    this.bd = '',
    this.blob = '',
    this.liferay = '',
  });

  final String api;
  final String bd;
  final String blob;
  final String liferay;

  ServerConfigModel copyWith({
    String? api,
    String? bd,
    String? blob,
    String? liferay,
  }) {
    return ServerConfigModel(
      api: api ?? this.api,
      bd: bd ?? this.bd,
      blob: blob ?? this.blob,
      liferay: liferay ?? this.liferay,
    );
  }

  static ServerConfigModel empty() => const ServerConfigModel();

  factory ServerConfigModel.fromJson(Map<String, dynamic> json) {
    return ServerConfigModel(
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
// LastUsedModel
// ─────────────────────────────────────────────

@immutable
class LastUsedModel {
  const LastUsedModel({this.rutaPackages = ''});

  final String rutaPackages;

  static LastUsedModel empty() => const LastUsedModel();

  factory LastUsedModel.fromJson(Map<String, dynamic> json) {
    return LastUsedModel(
      rutaPackages: (json['ruta_packages'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'ruta_packages': rutaPackages};
}

// ─────────────────────────────────────────────
// SettingsModel
// ─────────────────────────────────────────────

@immutable
class SettingsModel {
  const SettingsModel({required this.qa, required this.prod, this.lastUsed});

  final ServerConfigModel qa;
  final ServerConfigModel prod;
  final LastUsedModel? lastUsed;

  SettingsModel copyWith({
    ServerConfigModel? qa,
    ServerConfigModel? prod,
    LastUsedModel? lastUsed,
  }) {
    return SettingsModel(
      qa: qa ?? this.qa,
      prod: prod ?? this.prod,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  static SettingsModel empty() => SettingsModel(
    qa: ServerConfigModel.empty(),
    prod: ServerConfigModel.empty(),
    lastUsed: LastUsedModel.empty(),
  );

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    final servidores = json['servidores'] as Map<String, dynamic>? ?? {};
    final rawQa = servidores['qa'] as Map<String, dynamic>? ?? {};
    final rawProd = servidores['prod'] as Map<String, dynamic>? ?? {};
    final rawLastUsed = json['last_used'] as Map<String, dynamic>?;

    return SettingsModel(
      qa: ServerConfigModel.fromJson(rawQa),
      prod: ServerConfigModel.fromJson(rawProd),
      lastUsed: rawLastUsed != null
          ? LastUsedModel.fromJson(rawLastUsed)
          : LastUsedModel.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
    'servidores': {'qa': qa.toJson(), 'prod': prod.toJson()},
    'last_used': lastUsed?.toJson() ?? LastUsedModel.empty().toJson(),
  };
}
