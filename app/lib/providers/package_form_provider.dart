import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/component_config.dart';
import '../models/package_config.dart';
import '../models/package_history_entry.dart';
import '../models/package_template.dart';
import '../models/settings_model.dart';

// ─────────────────────────────────────────────
// PackageFormState
// ─────────────────────────────────────────────

@immutable
class PackageFormState {
  const PackageFormState({
    this.ticket = '',
    this.huNombre = '',
    this.ambiente = 'QA',
    this.iteracion = '01',
    this.rutaPackages = '',
    this.selectedTypes = const {},
    this.instances = const {},
    this.servers = const {},
    this.guardarServidores = false,
  });

  final String ticket;
  final String huNombre;
  final String ambiente;
  final String iteracion;
  final String rutaPackages;
  final Set<ComponentType> selectedTypes;

  /// Map from ComponentType to its list of instances
  final Map<ComponentType, List<ComponentInstanceState>> instances;

  /// Servers map: 'QA' → ServerConfig, 'PROD' → ServerConfig
  final Map<String, ServerConfig> servers;

  /// Whether to persist server values after generating
  final bool guardarServidores;

  /// Computed package name per domain rule REQ-DOMAIN-003
  String get packageName {
    final iter = iteracion.padLeft(2, '0');
    return '$ticket-PortalRetail_$ambiente-$iter';
  }

  PackageFormState copyWith({
    String? ticket,
    String? huNombre,
    String? ambiente,
    String? iteracion,
    String? rutaPackages,
    Set<ComponentType>? selectedTypes,
    Map<ComponentType, List<ComponentInstanceState>>? instances,
    Map<String, ServerConfig>? servers,
    bool? guardarServidores,
  }) {
    return PackageFormState(
      ticket: ticket ?? this.ticket,
      huNombre: huNombre ?? this.huNombre,
      ambiente: ambiente ?? this.ambiente,
      iteracion: iteracion ?? this.iteracion,
      rutaPackages: rutaPackages ?? this.rutaPackages,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      instances: instances ?? this.instances,
      servers: servers ?? this.servers,
      guardarServidores: guardarServidores ?? this.guardarServidores,
    );
  }

  static PackageFormState empty() => const PackageFormState(
    servers: {'QA': ServerConfig(), 'PROD': ServerConfig()},
  );
}

// ─────────────────────────────────────────────
// PackageFormNotifier
// ─────────────────────────────────────────────

class PackageFormNotifier extends Notifier<PackageFormState> {
  @override
  PackageFormState build() => PackageFormState.empty();

  // ── Field updates ─────────────────────────────

  void updateTicket(String value) => state = state.copyWith(ticket: value);
  void updateHuNombre(String value) => state = state.copyWith(huNombre: value);
  void updateAmbiente(String value) => state = state.copyWith(ambiente: value);
  void updateIteracion(String value) =>
      state = state.copyWith(iteracion: value);
  void updateRutaPackages(String value) =>
      state = state.copyWith(rutaPackages: value);
  void updateGuardarServidores(bool value) =>
      state = state.copyWith(guardarServidores: value);

  // ── Component toggles ─────────────────────────

  void toggleComponent(ComponentType type) {
    final current = Set<ComponentType>.from(state.selectedTypes);
    final newInstances = Map<ComponentType, List<ComponentInstanceState>>.from(
      state.instances,
    );

    if (current.contains(type)) {
      current.remove(type);
      // Preserve instances so data is not lost on re-select (REQ-NP-014)
    } else {
      current.add(type);
      // Initialize with one empty instance if not already present
      if (!newInstances.containsKey(type) || newInstances[type]!.isEmpty) {
        newInstances[type] = [ComponentInstanceState.empty()];
      }
    }

    state = state.copyWith(selectedTypes: current, instances: newInstances);
  }

  // ── Instance management ───────────────────────

  void addInstance(ComponentType type) {
    if (!type.isMultiInstance) {
      return; // Guard: liferay_build is single-instance
    }
    final newInstances = Map<ComponentType, List<ComponentInstanceState>>.from(
      state.instances,
    );
    final list = List<ComponentInstanceState>.from(newInstances[type] ?? []);
    list.add(ComponentInstanceState.empty());
    newInstances[type] = list;
    state = state.copyWith(instances: newInstances);
  }

  void removeInstance(ComponentType type, int index) {
    final newInstances = Map<ComponentType, List<ComponentInstanceState>>.from(
      state.instances,
    );
    final list = List<ComponentInstanceState>.from(newInstances[type] ?? []);
    if (index < 0 || index >= list.length) return;
    if (list.length <= 1 && !type.isMultiInstance) {
      return; // Don't remove last single instance
    }
    list.removeAt(index);
    newInstances[type] = list;
    state = state.copyWith(instances: newInstances);
  }

  void updateInstance(
    ComponentType type,
    int index,
    ComponentInstanceState updated,
  ) {
    final newInstances = Map<ComponentType, List<ComponentInstanceState>>.from(
      state.instances,
    );
    final list = List<ComponentInstanceState>.from(newInstances[type] ?? []);
    if (index < 0 || index >= list.length) return;
    list[index] = updated;
    newInstances[type] = list;
    state = state.copyWith(instances: newInstances);
  }

  // ── Server updates ────────────────────────────

  void updateServer(String ambiente, ServerConfig config) {
    final newServers = Map<String, ServerConfig>.from(state.servers);
    newServers[ambiente] = config;
    state = state.copyWith(servers: newServers);
  }

  // ── Prefill from clone ────────────────────────

  void prefill(Map<String, dynamic> data) {
    final ticket = (data['ticket'] as String?) ?? '';
    final huNombre = (data['hu_nombre'] as String?) ?? '';
    final ambiente = ((data['ambiente'] as String?) ?? 'QA').toUpperCase();
    final iteracion = (data['iteracion'] as String?) ?? '01';
    final rutaPackages =
        (data['ruta_packages'] as String?) ?? state.rutaPackages;

    final rawComponentes = data['componentes'] as List? ?? [];
    final newSelected = <ComponentType>{};
    final newInstances = <ComponentType, List<ComponentInstanceState>>{};

    for (final raw in rawComponentes) {
      final comp = raw as Map<String, dynamic>;
      final key = (comp['tipo'] as String?) ?? '';
      ComponentType? type;
      try {
        type = ComponentType.fromKey(key);
      } catch (_) {
        continue;
      }
      newSelected.add(type);
      final rawInstances = comp['instancias'] as List? ?? [];
      newInstances[type] = rawInstances
          .map(
            (i) => ComponentInstanceState.fromJson(i as Map<String, dynamic>),
          )
          .toList();
      if (newInstances[type]!.isEmpty) {
        newInstances[type] = [ComponentInstanceState.empty()];
      }
    }

    // Prefill servers from data if present
    Map<String, ServerConfig>? newServers;
    final rawServers = data['servidores'] as Map?;
    if (rawServers != null) {
      newServers = Map<String, ServerConfig>.from(state.servers);
      if (rawServers['qa'] != null) {
        newServers['QA'] = ServerConfig.fromJson(
          Map<String, dynamic>.from(rawServers['qa'] as Map),
        );
      }
      if (rawServers['prod'] != null) {
        newServers['PROD'] = ServerConfig.fromJson(
          Map<String, dynamic>.from(rawServers['prod'] as Map),
        );
      }
    }

    state = state.copyWith(
      ticket: ticket,
      huNombre: huNombre,
      ambiente: ambiente,
      iteracion: iteracion,
      rutaPackages: rutaPackages,
      selectedTypes: newSelected,
      instances: newInstances,
      servers: newServers,
    );
  }

  /// Pre-fill servers from saved settings for the current ambiente
  void prefillServersFromSettings(SettingsModel settings) {
    final qaServer = ServerConfig(
      api: settings.qa.api,
      bd: settings.qa.bd,
      blob: settings.qa.blob,
      liferay: settings.qa.liferay,
    );
    final prodServer = ServerConfig(
      api: settings.prod.api,
      bd: settings.prod.bd,
      blob: settings.prod.blob,
      liferay: settings.prod.liferay,
    );
    state = state.copyWith(servers: {'QA': qaServer, 'PROD': prodServer});
  }

  void reset() => state = PackageFormState.empty();

  // ── Validation warnings (non-blocking) ────────

  /// Returns a list of path-validation warnings for the current state.
  /// Returns empty list on non-Windows platforms.
  List<String> get validationWarnings {
    if (!Platform.isWindows) return [];
    final warnings = <String>[];
    if (state.rutaPackages.isNotEmpty &&
        !Directory(state.rutaPackages).existsSync()) {
      warnings.add('La ruta de packages no existe: ${state.rutaPackages}');
    }
    return warnings;
  }

  // ── Prefill from history ───────────────────────

  void prefillFromHistory(PackageHistoryEntry entry) {
    state = state.copyWith(
      ticket: entry.ticket,
      huNombre: entry.huNombre,
      ambiente: entry.ambiente,
      iteracion: entry.iteracion,
      rutaPackages: entry.packageDir.isNotEmpty
          ? entry.packageDir
          : state.rutaPackages,
    );
  }

  // ── Apply template ─────────────────────────────

  void applyTemplate(PackageTemplate template) {
    final newSelectedTypes = template.selectedTypes
        .map(
          (s) => ComponentType.values.firstWhere(
            (e) => e.key == s,
            orElse: () => ComponentType.values.first,
          ),
        )
        .toSet();

    final newInstances = <ComponentType, List<ComponentInstanceState>>{};
    for (final type in newSelectedTypes) {
      newInstances[type] = [ComponentInstanceState.empty()];
    }

    state = state.copyWith(
      selectedTypes: newSelectedTypes,
      instances: newInstances,
    );
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final packageFormProvider =
    NotifierProvider<PackageFormNotifier, PackageFormState>(
      PackageFormNotifier.new,
    );
