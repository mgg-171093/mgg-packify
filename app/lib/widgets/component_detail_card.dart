import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme_extensions.dart';
import '../models/component_config.dart';
import '../models/options_model.dart';
import '../providers/options_provider.dart';

// ─────────────────────────────────────────────
// ComponentDetailCard
// ─────────────────────────────────────────────

class ComponentDetailCard extends StatefulWidget {
  const ComponentDetailCard({
    super.key,
    required this.type,
    required this.instances,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    this.returnTo,
  });

  final ComponentType type;
  final List<ComponentInstanceState> instances;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, ComponentInstanceState updated) onUpdate;

  /// Route to return to when navigating to a catalog. Passed to catalog screens.
  final String? returnTo;

  @override
  State<ComponentDetailCard> createState() => _ComponentDetailCardState();
}

class _ComponentDetailCardState extends State<ComponentDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // Start expanded
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaces =
        theme.extension<SurfaceTokens>() ??
        SurfaceTokens.fromColorScheme(colorScheme);
    final effects = theme.extension<PremiumEffects>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: surfaces.cardElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          InkWell(
            onTap: _toggle,
            mouseCursor: effects?.actionCursor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.type.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable body
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Render each instance
                  for (int i = 0; i < widget.instances.length; i++) ...[
                    if (i > 0) const Divider(height: 24),
                    _InstanceHeader(
                      index: i,
                      type: widget.type,
                      canRemove:
                          widget.type.isMultiInstance &&
                          widget.instances.length > 1,
                      onRemove: () => widget.onRemove(i),
                    ),
                    const SizedBox(height: 8),
                    _InstanceFields(
                      type: widget.type,
                      instance: widget.instances[i],
                      onUpdate: (updated) => widget.onUpdate(i, updated),
                      returnTo: widget.returnTo,
                    ),
                  ],
                  // Add instance button (multi-instance types only)
                  if (widget.type.isMultiInstance) ...[
                    const SizedBox(height: 12),
                    _AddInstanceButton(type: widget.type, onTap: widget.onAdd),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _InstanceHeader
// ─────────────────────────────────────────────

class _InstanceHeader extends StatelessWidget {
  const _InstanceHeader({
    required this.index,
    required this.type,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final ComponentType type;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!canRemove && index == 0) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          'Instancia ${index + 1}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (canRemove)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: colorScheme.error,
            tooltip: 'Eliminar instancia',
            onPressed: onRemove,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _AddInstanceButton
// ─────────────────────────────────────────────

class _AddInstanceButton extends StatelessWidget {
  const _AddInstanceButton({required this.type, required this.onTap});

  final ComponentType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.add,
          size: 18,
          color: colorScheme.onSecondaryContainer,
        ),
        label: Text(
          '+ Agregar otro ${type.label}',
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _EmptyServicePrompt
// ─────────────────────────────────────────────

class _EmptyServicePrompt extends StatelessWidget {
  const _EmptyServicePrompt({required this.label, required this.onGoToCatalog});

  final String label;
  final VoidCallback onGoToCatalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onGoToCatalog,
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Ir al catálogo'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _InstanceFields — dispatches by ComponentType
// ─────────────────────────────────────────────

class _InstanceFields extends ConsumerStatefulWidget {
  const _InstanceFields({
    required this.type,
    required this.instance,
    required this.onUpdate,
    this.returnTo,
  });

  final ComponentType type;
  final ComponentInstanceState instance;
  final void Function(ComponentInstanceState) onUpdate;

  /// Route to return to when navigating to a catalog.
  final String? returnTo;

  @override
  ConsumerState<_InstanceFields> createState() => _InstanceFieldsState();
}

class _InstanceFieldsState extends ConsumerState<_InstanceFields> {
  late Map<String, TextEditingController> _controllers;

  // List-based controllers for blob archivos, api/sql configs/scripts.
  // Each entry maps to one row's fields.
  List<TextEditingController> _blobNombreCtrs = [];
  List<TextEditingController> _blobCarpetaCtrs = [];
  List<TextEditingController> _configClaveCtrs = [];
  List<TextEditingController> _configValorCtrs = [];
  List<String?> _configImagePaths = [];
  List<TextEditingController> _scriptCtrs = [];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _initControllers();
    _initListControllers();
  }

  void _initControllers() {
    switch (widget.type) {
      case ComponentType.liferayBuild:
        _controllers['buildId'] = TextEditingController(
          text: widget.instance.buildId,
        );
        break;
      case ComponentType.sql:
        // No TextEditingController needed — baseDatos uses DropdownButtonFormField
        break;
      case ComponentType.apim:
        _controllers['nombreServicio'] = TextEditingController(
          text: widget.instance.nombreServicio,
        );
        break;
      case ComponentType.apiIis:
      case ComponentType.apiDocker:
        // No TextEditingController needed — nombreServicio uses DropdownButtonFormField
        break;
      case ComponentType.blob:
        break;
      case ComponentType.liferay:
        _controllers['nombre'] = TextEditingController(
          text: widget.instance.nombre,
        );
        _controllers['pagina'] = TextEditingController(
          text: widget.instance.pagina,
        );
        _controllers['widgets'] = TextEditingController(
          text: widget.instance.widgets.join(', '),
        );
        break;
      case ComponentType.assets:
        _controllers['nombre'] = TextEditingController(
          text: widget.instance.nombre,
        );
        break;
    }
  }

  void _initListControllers() {
    // Blob archivos
    _blobNombreCtrs = widget.instance.archivos
        .map((f) => TextEditingController(text: f.nombre))
        .toList();
    _blobCarpetaCtrs = widget.instance.archivos
        .map((f) => TextEditingController(text: f.carpeta))
        .toList();
    // API configs
    _configClaveCtrs = widget.instance.configs
        .map((c) => TextEditingController(text: c.clave))
        .toList();
    _configValorCtrs = widget.instance.configs
        .map((c) => TextEditingController(text: c.valor))
        .toList();
    _configImagePaths = widget.instance.configs
        .map((c) => c.imagenPath)
        .toList();
    // SQL scripts
    _scriptCtrs = widget.instance.scripts
        .map((s) => TextEditingController(text: s))
        .toList();
  }

  void _syncListControllers() {
    // Blob: grow/shrink to match archivos length
    _syncList(
      _blobNombreCtrs,
      widget.instance.archivos.length,
      (i) => widget.instance.archivos[i].nombre,
    );
    _syncList(
      _blobCarpetaCtrs,
      widget.instance.archivos.length,
      (i) => widget.instance.archivos[i].carpeta,
    );
    // Configs
    _syncList(
      _configClaveCtrs,
      widget.instance.configs.length,
      (i) => widget.instance.configs[i].clave,
    );
    _syncList(
      _configValorCtrs,
      widget.instance.configs.length,
      (i) => widget.instance.configs[i].valor,
    );
    // Sync _configImagePaths (grow with nulls, shrink by truncation)
    while (_configImagePaths.length < widget.instance.configs.length) {
      _configImagePaths.add(null);
    }
    while (_configImagePaths.length > widget.instance.configs.length) {
      _configImagePaths.removeLast();
    }
    // Scripts
    _syncList(
      _scriptCtrs,
      widget.instance.scripts.length,
      (i) => widget.instance.scripts[i],
    );
  }

  /// Grows or shrinks [list] to [targetLen].
  /// New entries are initialised with [textFor(i)].
  /// Existing entries are NOT overwritten (preserves cursor position).
  void _syncList(
    List<TextEditingController> list,
    int targetLen,
    String Function(int i) textFor,
  ) {
    while (list.length < targetLen) {
      final i = list.length;
      list.add(TextEditingController(text: textFor(i)));
    }
    while (list.length > targetLen) {
      list.removeLast().dispose();
    }
  }

  @override
  void didUpdateWidget(_InstanceFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync list-based controllers when the instance changes externally
    // (e.g. add/remove row). We do NOT overwrite text for existing rows
    // to avoid resetting the cursor while the user is typing.
    _syncListControllers();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final c in _blobNombreCtrs) c.dispose();
    for (final c in _blobCarpetaCtrs) c.dispose();
    for (final c in _configClaveCtrs) c.dispose();
    for (final c in _configValorCtrs) c.dispose();
    for (final c in _scriptCtrs) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.type) {
      ComponentType.liferayBuild => _buildLiferayBuild(),
      ComponentType.sql => _buildSql(),
      ComponentType.apiIis => _buildApiIis(),
      ComponentType.apiDocker => _buildApiDocker(),
      ComponentType.blob => _buildBlob(),
      ComponentType.liferay => _buildLiferay(),
      ComponentType.assets => _buildAssets(),
      ComponentType.apim => _buildApim(),
    };
  }

  // ── shared: estatus & tipo dropdowns ──────────

  /// Picks an image file for the config entry at [idx] and updates the state.
  Future<void> _pickConfigImage(int idx) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && mounted) {
        final path = result.files.single.path;
        if (path != null) {
          setState(() {
            _configImagePaths[idx] = path;
          });
          final configs = List<ConfigEntry>.from(widget.instance.configs);
          configs[idx] = configs[idx].copyWith(imagenPath: path);
          widget.onUpdate(widget.instance.copyWith(configs: configs));
        }
      }
    } catch (_) {
      // Silently ignore — no change on error (same as _pickFolder pattern)
    }
  }

  /// Estatus dropdown — ALL component types
  Widget _buildEstatusDropdown(AsyncValue<List<String>> estatusOptions) {
    return estatusOptions.when(
      loading: () => DropdownButtonFormField<String>(
        initialValue: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Estatus',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('...'),
      ),
      error: (_, __) => DropdownButtonFormField<String>(
        initialValue: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Estatus',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('Error al cargar'),
      ),
      data: (list) {
        final currentValue = list.contains(widget.instance.estatus)
            ? widget.instance.estatus
            : (list.isNotEmpty ? list.first : null);
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          items: list
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              widget.onUpdate(widget.instance.copyWith(estatus: v));
            }
          },
          decoration: const InputDecoration(
            labelText: 'Estatus',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }

  /// Tipo dropdown — ONLY for sql and blob types
  Widget _buildTipoDropdown(AsyncValue<List<String>> tipoOptions) {
    return tipoOptions.when(
      loading: () => DropdownButtonFormField<String>(
        initialValue: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('...'),
      ),
      error: (_, __) => DropdownButtonFormField<String>(
        initialValue: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('Error al cargar'),
      ),
      data: (list) {
        final currentValue =
            widget.instance.tipo.isNotEmpty &&
                list.contains(widget.instance.tipo)
            ? widget.instance.tipo
            : null;
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          items: list
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            widget.onUpdate(widget.instance.copyWith(tipo: v ?? ''));
          },
          decoration: const InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }

  // ── liferay_build ─────────────────────────────

  Widget _buildLiferayBuild() {
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controllers['buildId'],
          decoration: const InputDecoration(
            labelText: 'Build ID',
            hintText: '7957',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(buildId: v)),
        ),
        const SizedBox(height: 12),
        _buildEstatusDropdown(estatusOptions),
      ],
    );
  }

  // ── sql ───────────────────────────────────────

  Widget _buildSql() {
    final scripts = List<String>.from(widget.instance.scripts);
    // Ensure scriptsCopiar is at least as long as scripts (pad with false)
    final scriptsCopiar = List<bool>.from(widget.instance.scriptsCopiar);
    while (scriptsCopiar.length < scripts.length) {
      scriptsCopiar.add(false);
    }
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    final tipoOptions = optionsAsync.whenData((o) => o.tipoSqlList);
    final sqlDatabases = optionsAsync.maybeWhen(
      data: (o) => o.sqlDatabases,
      orElse: () => const <String>[],
    );
    final currentBaseDatos = sqlDatabases.contains(widget.instance.baseDatos)
        ? widget.instance.baseDatos
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: currentBaseDatos,
          items: sqlDatabases
              .map((db) => DropdownMenuItem(value: db, child: Text(db)))
              .toList(),
          hint: const Text('Seleccionar BD...'),
          disabledHint: const Text('Configurar en Ajustes'),
          onChanged: sqlDatabases.isEmpty
              ? null
              : (val) {
                  if (val != null) {
                    widget.onUpdate(widget.instance.copyWith(baseDatos: val));
                  }
                },
          decoration: const InputDecoration(
            labelText: 'Base de Datos',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (sqlDatabases.isEmpty) ...[
          const SizedBox(height: 6),
          _EmptyServicePrompt(
            label: 'No hay bases de datos configuradas.',
            onGoToCatalog: () => context.go(
              '/catalogos/bases-datos',
              extra: widget.returnTo ?? '/new-package',
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(
                '/catalogos/bases-datos',
                extra: widget.returnTo ?? '/new-package',
              ),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Gestionar catálogo'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildEstatusDropdown(estatusOptions),
        const SizedBox(height: 12),
        _buildTipoDropdown(tipoOptions),
        const SizedBox(height: 12),
        const Text(
          'Scripts:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        for (int idx = 0; idx < scripts.length; idx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scriptCtrs[idx],
                    decoration: InputDecoration(
                      hintText: '01_MigracionUsuarios.sql',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Script ${idx + 1}',
                    ),
                    onChanged: (v) {
                      final newScripts = List<String>.from(scripts);
                      newScripts[idx] = v;
                      widget.onUpdate(
                        widget.instance.copyWith(scripts: newScripts),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Checkbox(
                  value: scriptsCopiar[idx],
                  onChanged: (val) {
                    final newCopiar = List<bool>.from(scriptsCopiar);
                    newCopiar[idx] = val ?? false;
                    widget.onUpdate(
                      widget.instance.copyWith(scriptsCopiar: newCopiar),
                    );
                  },
                ),
                const Text('Copiar', style: TextStyle(fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    final newScripts = List<String>.from(scripts)
                      ..removeAt(idx);
                    final newCopiar = List<bool>.from(scriptsCopiar)
                      ..removeAt(idx);
                    widget.onUpdate(
                      widget.instance.copyWith(
                        scripts: newScripts,
                        scriptsCopiar: newCopiar,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            final newScripts = [...scripts, ''];
            final newCopiar = [...scriptsCopiar, false];
            widget.onUpdate(
              widget.instance.copyWith(
                scripts: newScripts,
                scriptsCopiar: newCopiar,
              ),
            );
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar script'),
        ),
      ],
    );
  }

  // ── api_iis ────────────────────────────────────

  Widget _buildApiIis() {
    final configs = List<ConfigEntry>.from(widget.instance.configs);
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    final iisServices = optionsAsync.maybeWhen(
      data: (o) => o.apiIisServices,
      orElse: () => const <ApiIisServiceEntry>[],
    );
    final currentNombre =
        iisServices.any((e) => e.nombre == widget.instance.nombreServicio)
        ? widget.instance.nombreServicio
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentNombre,
          items: iisServices
              .map(
                (e) => DropdownMenuItem(value: e.nombre, child: Text(e.nombre)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              widget.onUpdate(widget.instance.copyWith(nombreServicio: v));
            }
          },
          decoration: const InputDecoration(
            labelText: 'Nombre del servicio',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('Seleccionar servicio...'),
        ),
        if (iisServices.isEmpty) ...[
          const SizedBox(height: 6),
          _EmptyServicePrompt(
            label: 'No hay servicios IIS configurados.',
            onGoToCatalog: () => context.go(
              '/catalogos/servicios',
              extra: widget.returnTo ?? '/new-package',
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(
                '/catalogos/servicios',
                extra: widget.returnTo ?? '/new-package',
              ),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Gestionar catálogo'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildEstatusDropdown(estatusOptions),
        const SizedBox(height: 4),
        SwitchListTile(
          title: const Text('Publicar', style: TextStyle(fontSize: 14)),
          value: widget.instance.publicar,
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(publicar: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        SwitchListTile(
          title: const Text('Jenkins CI/CD', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Incluir pipeline de Jenkins',
            style: TextStyle(fontSize: 12),
          ),
          value: widget.instance.jenkins,
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(jenkins: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        SwitchListTile(
          title: const Text('Actualizar APIM', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Actualizar Azure API Management',
            style: TextStyle(fontSize: 12),
          ),
          value: widget.instance.actualizarApim,
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(actualizarApim: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: 8),
        const Text(
          'Configuraciones:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        for (int idx = 0; idx < configs.length; idx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _configClaveCtrs[idx],
                    decoration: const InputDecoration(
                      labelText: 'Clave',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final newConfigs = List<ConfigEntry>.from(configs);
                      newConfigs[idx] = configs[idx].copyWith(clave: v);
                      widget.onUpdate(
                        widget.instance.copyWith(configs: newConfigs),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _configValorCtrs[idx],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final newConfigs = List<ConfigEntry>.from(configs);
                      newConfigs[idx] = configs[idx].copyWith(valor: v);
                      widget.onUpdate(
                        widget.instance.copyWith(configs: newConfigs),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    final newConfigs = List<ConfigEntry>.from(configs)
                      ..removeAt(idx);
                    widget.onUpdate(
                      widget.instance.copyWith(configs: newConfigs),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _configImagePaths[idx] == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.image,
                    size: 18,
                  ),
                  tooltip: _configImagePaths[idx] == null
                      ? 'Agregar imagen'
                      : 'Imagen seleccionada',
                  onPressed: () => _pickConfigImage(idx),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            final newConfigs = [...configs, ConfigEntry.empty()];
            widget.onUpdate(widget.instance.copyWith(configs: newConfigs));
          },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text(
            '+ Agregar config',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ── api_docker ─────────────────────────────────

  Widget _buildApiDocker() {
    final configs = List<ConfigEntry>.from(widget.instance.configs);
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    final dockerServices = optionsAsync.maybeWhen(
      data: (o) => o.apiDockerServices,
      orElse: () => const <ApiDockerServiceEntry>[],
    );
    final currentNombre =
        dockerServices.any((e) => e.nombre == widget.instance.nombreServicio)
        ? widget.instance.nombreServicio
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentNombre,
          items: dockerServices
              .map(
                (e) => DropdownMenuItem(value: e.nombre, child: Text(e.nombre)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              widget.onUpdate(widget.instance.copyWith(nombreServicio: v));
            }
          },
          decoration: const InputDecoration(
            labelText: 'Nombre del servicio',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('Seleccionar servicio...'),
        ),
        if (dockerServices.isEmpty) ...[
          const SizedBox(height: 6),
          _EmptyServicePrompt(
            label: 'No hay servicios Docker configurados.',
            onGoToCatalog: () => context.go(
              '/catalogos/servicios',
              extra: widget.returnTo ?? '/new-package',
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(
                '/catalogos/servicios',
                extra: widget.returnTo ?? '/new-package',
              ),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Gestionar catálogo'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildEstatusDropdown(estatusOptions),
        const SizedBox(height: 4),
        SwitchListTile(
          title: const Text('Jenkins CI/CD', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Incluir pipeline de Jenkins',
            style: TextStyle(fontSize: 12),
          ),
          value: widget.instance.jenkins,
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(jenkins: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        SwitchListTile(
          title: const Text('Actualizar APIM', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Actualizar Azure API Management',
            style: TextStyle(fontSize: 12),
          ),
          value: widget.instance.actualizarApim,
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(actualizarApim: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: 8),
        const Text(
          'Configuraciones:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        for (int idx = 0; idx < configs.length; idx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _configClaveCtrs[idx],
                    decoration: const InputDecoration(
                      labelText: 'Clave',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final newConfigs = List<ConfigEntry>.from(configs);
                      newConfigs[idx] = configs[idx].copyWith(clave: v);
                      widget.onUpdate(
                        widget.instance.copyWith(configs: newConfigs),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _configValorCtrs[idx],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final newConfigs = List<ConfigEntry>.from(configs);
                      newConfigs[idx] = configs[idx].copyWith(valor: v);
                      widget.onUpdate(
                        widget.instance.copyWith(configs: newConfigs),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    final newConfigs = List<ConfigEntry>.from(configs)
                      ..removeAt(idx);
                    widget.onUpdate(
                      widget.instance.copyWith(configs: newConfigs),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _configImagePaths[idx] == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.image,
                    size: 18,
                  ),
                  tooltip: _configImagePaths[idx] == null
                      ? 'Agregar imagen'
                      : 'Imagen seleccionada',
                  onPressed: () => _pickConfigImage(idx),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            final newConfigs = [...configs, ConfigEntry.empty()];
            widget.onUpdate(widget.instance.copyWith(configs: newConfigs));
          },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text(
            '+ Agregar config',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ── blob ──────────────────────────────────────

  Widget _buildBlob() {
    final archivos = List<FileEntry>.from(widget.instance.archivos);
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    final tipoOptions = optionsAsync.whenData((o) => o.tipoBlobList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEstatusDropdown(estatusOptions),
        const SizedBox(height: 12),
        _buildTipoDropdown(tipoOptions),
        const SizedBox(height: 12),
        for (int idx = 0; idx < archivos.length; idx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _blobNombreCtrs[idx],
                        decoration: const InputDecoration(
                          labelText: 'Nombre del archivo',
                          hintText: 'styles.css',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final newArchivos = List<FileEntry>.from(archivos);
                          newArchivos[idx] = archivos[idx].copyWith(nombre: v);
                          widget.onUpdate(
                            widget.instance.copyWith(archivos: newArchivos),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () {
                        final newArchivos = List<FileEntry>.from(archivos)
                          ..removeAt(idx);
                        widget.onUpdate(
                          widget.instance.copyWith(archivos: newArchivos),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _blobCarpetaCtrs[idx],
                  decoration: const InputDecoration(
                    labelText: 'Carpeta destino',
                    hintText: 'assets/css',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final newArchivos = List<FileEntry>.from(archivos);
                    newArchivos[idx] = archivos[idx].copyWith(carpeta: v);
                    widget.onUpdate(
                      widget.instance.copyWith(archivos: newArchivos),
                    );
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            final newArchivos = [...archivos, FileEntry.empty()];
            widget.onUpdate(widget.instance.copyWith(archivos: newArchivos));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar archivo'),
        ),
      ],
    );
  }

  // ── liferay ───────────────────────────────────

  Widget _buildLiferay() {
    final instance = widget.instance;
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controllers['nombre'],
          decoration: const InputDecoration(
            labelText: 'Nombre de la Remote App',
            hintText: 'MXAuthentication',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => widget.onUpdate(instance.copyWith(nombre: v)),
        ),
        const SizedBox(height: 12),
        _buildEstatusDropdown(estatusOptions),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('¿Es nueva?', style: TextStyle(fontSize: 14)),
          value: instance.esNueva,
          onChanged: (v) => widget.onUpdate(instance.copyWith(esNueva: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        SwitchListTile(
          title: const Text(
            '¿Crear/actualizar página?',
            style: TextStyle(fontSize: 14),
          ),
          value: instance.crearPagina,
          onChanged: (v) => widget.onUpdate(instance.copyWith(crearPagina: v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (instance.crearPagina) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _controllers['pagina'],
            decoration: const InputDecoration(
              labelText: 'Nombre de página',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => widget.onUpdate(instance.copyWith(pagina: v)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers['widgets'],
            decoration: const InputDecoration(
              labelText: 'Widgets a agregar (separados por coma)',
              hintText: 'MXLoginWidget, MXProfileWidget',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              final widgetList = v.split(',').map((s) => s.trim()).toList();
              widget.onUpdate(instance.copyWith(widgets: widgetList));
            },
          ),
        ],
      ],
    );
  }

  // ── assets ────────────────────────────────────

  Widget _buildAssets() {
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controllers['nombre'],
          decoration: const InputDecoration(
            labelText: 'Nombre del archivo',
            hintText: 'logo.png',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(nombre: v)),
        ),
        const SizedBox(height: 12),
        _buildEstatusDropdown(estatusOptions),
      ],
    );
  }

  // ── apim ──────────────────────────────────────

  Widget _buildApim() {
    final optionsAsync = ref.watch(optionsProvider);
    final estatusOptions = optionsAsync.whenData((o) => o.estatusList);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controllers['nombreServicio'],
          decoration: const InputDecoration(
            labelText: 'Nombre del servicio',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) =>
              widget.onUpdate(widget.instance.copyWith(nombreServicio: v)),
        ),
        const SizedBox(height: 12),
        _buildEstatusDropdown(estatusOptions),
      ],
    );
  }
}
