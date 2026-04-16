import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_extensions.dart';
import '../../models/options_model.dart';
import '../../providers/options_provider.dart';

class ServiciosScreen extends ConsumerStatefulWidget {
  const ServiciosScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends ConsumerState<ServiciosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // IIS add-row controllers
  final TextEditingController _iisNombreCtrl = TextEditingController();
  final TextEditingController _iisRutaCtrl = TextEditingController();

  // IIS inline-edit state
  int? _iisEditingIndex;
  TextEditingController? _iisEditNombreCtrl;
  TextEditingController? _iisEditRutaCtrl;

  // Docker add-row controller
  final TextEditingController _dockerNombreCtrl = TextEditingController();

  // Docker inline-edit state
  int? _dockerEditingIndex;
  TextEditingController? _dockerEditNombreCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _iisNombreCtrl.dispose();
    _iisRutaCtrl.dispose();
    _iisEditNombreCtrl?.dispose();
    _iisEditRutaCtrl?.dispose();
    _dockerNombreCtrl.dispose();
    _dockerEditNombreCtrl?.dispose();
    super.dispose();
  }

  // ── IIS helpers ────────────────────────────

  void _startIisEdit(int index, ApiIisServiceEntry entry) {
    _iisEditNombreCtrl?.dispose();
    _iisEditRutaCtrl?.dispose();
    setState(() {
      _iisEditingIndex = index;
      _iisEditNombreCtrl = TextEditingController(text: entry.nombre);
      _iisEditRutaCtrl = TextEditingController(text: entry.ruta);
    });
  }

  void _cancelIisEdit() {
    _iisEditNombreCtrl?.dispose();
    _iisEditRutaCtrl?.dispose();
    setState(() {
      _iisEditingIndex = null;
      _iisEditNombreCtrl = null;
      _iisEditRutaCtrl = null;
    });
  }

  void _confirmIisEdit(OptionsModel options) {
    final index = _iisEditingIndex;
    if (index == null) return;
    final nombre = _iisEditNombreCtrl?.text.trim() ?? '';
    final ruta = _iisEditRutaCtrl?.text.trim() ?? '';
    if (nombre.isEmpty) {
      _cancelIisEdit();
      return;
    }
    final newList = List<ApiIisServiceEntry>.from(options.apiIisServices);
    newList[index] = ApiIisServiceEntry(nombre: nombre, ruta: ruta);
    _iisEditNombreCtrl?.dispose();
    _iisEditRutaCtrl?.dispose();
    setState(() {
      _iisEditingIndex = null;
      _iisEditNombreCtrl = null;
      _iisEditRutaCtrl = null;
    });
    _saveOptions(options.copyWith(apiIisServices: newList));
  }

  void _addIisEntry(OptionsModel options) {
    final nombre = _iisNombreCtrl.text.trim();
    final ruta = _iisRutaCtrl.text.trim();
    if (nombre.isEmpty) return;
    final newList = [
      ...options.apiIisServices,
      ApiIisServiceEntry(nombre: nombre, ruta: ruta),
    ];
    _iisNombreCtrl.clear();
    _iisRutaCtrl.clear();
    _saveOptions(options.copyWith(apiIisServices: newList));
  }

  Future<void> _pickIisRuta(TextEditingController ctrl) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csproj'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        ctrl.text = result.files.single.path!;
      });
    }
  }

  // ── Docker helpers ──────────────────────────

  void _startDockerEdit(int index, ApiDockerServiceEntry entry) {
    _dockerEditNombreCtrl?.dispose();
    setState(() {
      _dockerEditingIndex = index;
      _dockerEditNombreCtrl = TextEditingController(text: entry.nombre);
    });
  }

  void _cancelDockerEdit() {
    _dockerEditNombreCtrl?.dispose();
    setState(() {
      _dockerEditingIndex = null;
      _dockerEditNombreCtrl = null;
    });
  }

  void _confirmDockerEdit(OptionsModel options) {
    final index = _dockerEditingIndex;
    if (index == null) return;
    final nombre = _dockerEditNombreCtrl?.text.trim() ?? '';
    if (nombre.isEmpty) {
      _cancelDockerEdit();
      return;
    }
    final newList = List<ApiDockerServiceEntry>.from(options.apiDockerServices);
    newList[index] = ApiDockerServiceEntry(nombre: nombre);
    _dockerEditNombreCtrl?.dispose();
    setState(() {
      _dockerEditingIndex = null;
      _dockerEditNombreCtrl = null;
    });
    _saveOptions(options.copyWith(apiDockerServices: newList));
  }

  void _addDockerEntry(OptionsModel options) {
    final nombre = _dockerNombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final newList = [
      ...options.apiDockerServices,
      ApiDockerServiceEntry(nombre: nombre),
    ];
    _dockerNombreCtrl.clear();
    _saveOptions(options.copyWith(apiDockerServices: newList));
  }

  void _saveOptions(OptionsModel options) {
    ref.read(optionsProvider.notifier).save(options);
  }

  // ── Build ───────────────────────────────────

  InputDecoration _fieldDecoration({
    required String hint,
    String? label,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _textEntryField({
    required TextEditingController controller,
    required InputDecoration decoration,
    ValueChanged<String>? onSubmitted,
    bool autofocus = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextField(
        controller: controller,
        decoration: decoration,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(optionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go(widget.returnTo ?? '/dashboard'),
        ),
        title: const Text('Servicios API'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge,
          tabs: const [
            Tab(text: 'IIS'),
            Tab(text: 'Docker'),
          ],
        ),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => TabBarView(
          controller: _tabController,
          children: [_buildIisTab(options), _buildDockerTab(options)],
        ),
      ),
    );
  }

  // ── IIS Tab ─────────────────────────────────

  Widget _buildIisTab(OptionsModel options) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effects =
        theme.extension<PremiumEffects>() ??
        const PremiumEffects(
          hoverDuration: Duration(milliseconds: 150),
          focusRingWidth: 2,
          actionCursor: SystemMouseCursors.click,
          standardCurve: Curves.easeInOut,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Servicios IIS',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (options.apiIisServices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Sin servicios',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.apiIisServices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final entry = options.apiIisServices[index];
                if (_iisEditingIndex == index) {
                  return Row(
                    children: [
                      Expanded(
                        child: _textEntryField(
                          controller: _iisEditNombreCtrl!,
                          decoration: _fieldDecoration(
                            label: 'Servicio',
                            hint: 'Nombre...',
                            helper: 'Editá y confirmá para guardar',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _textEntryField(
                          controller: _iisEditRutaCtrl!,
                          decoration: _fieldDecoration(
                            label: 'Ruta .csproj',
                            hint: 'Ruta...',
                            helper: 'Podés pegar la ruta o buscar archivo',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open_outlined),
                        tooltip: 'Seleccionar .csproj',
                        mouseCursor: effects.actionCursor,
                        onPressed: () => _pickIisRuta(_iisEditRutaCtrl!),
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: colorScheme.primary),
                        tooltip: 'Confirmar',
                        mouseCursor: effects.actionCursor,
                        onPressed: () => _confirmIisEdit(options),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.error),
                        tooltip: 'Cancelar',
                        mouseCursor: effects.actionCursor,
                        onPressed: _cancelIisEdit,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (entry.ruta.isNotEmpty)
                            Text(
                              entry.ruta,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar',
                      mouseCursor: effects.actionCursor,
                      onPressed: () => _startIisEdit(index, entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 18),
                      color: colorScheme.error,
                      tooltip: 'Eliminar',
                      mouseCursor: effects.actionCursor,
                      onPressed: () {
                        final newList = List<ApiIisServiceEntry>.from(
                          options.apiIisServices,
                        )..removeAt(index);
                        _saveOptions(options.copyWith(apiIisServices: newList));
                      },
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          // Add IIS row
          Row(
            children: [
              Expanded(
                child: _textEntryField(
                  controller: _iisNombreCtrl,
                  decoration: _fieldDecoration(
                    label: 'Servicio',
                    hint: 'Nombre...',
                    helper: 'Campo requerido',
                  ),
                  onSubmitted: (_) => _addIisEntry(options),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textEntryField(
                  controller: _iisRutaCtrl,
                  decoration: _fieldDecoration(
                    label: 'Ruta .csproj',
                    hint: 'Ruta...',
                    helper: 'Opcional',
                  ),
                  onSubmitted: (_) => _addIisEntry(options),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: 'Seleccionar .csproj',
                mouseCursor: effects.actionCursor,
                onPressed: () => _pickIisRuta(_iisRutaCtrl),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: () => _addIisEntry(options),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar',
                mouseCursor: effects.actionCursor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Docker Tab ───────────────────────────────

  Widget _buildDockerTab(OptionsModel options) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effects =
        theme.extension<PremiumEffects>() ??
        const PremiumEffects(
          hoverDuration: Duration(milliseconds: 150),
          focusRingWidth: 2,
          actionCursor: SystemMouseCursors.click,
          standardCurve: Curves.easeInOut,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Servicios Docker',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (options.apiDockerServices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Sin servicios',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.apiDockerServices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final entry = options.apiDockerServices[index];
                if (_dockerEditingIndex == index) {
                  return Row(
                    children: [
                      Expanded(
                        child: _textEntryField(
                          controller: _dockerEditNombreCtrl!,
                          decoration: _fieldDecoration(
                            label: 'Servicio',
                            hint: 'Nombre...',
                            helper: 'Editá y confirmá para guardar',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: colorScheme.primary),
                        tooltip: 'Confirmar',
                        mouseCursor: effects.actionCursor,
                        onPressed: () => _confirmDockerEdit(options),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.error),
                        tooltip: 'Cancelar',
                        mouseCursor: effects.actionCursor,
                        onPressed: _cancelDockerEdit,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.nombre,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar',
                      mouseCursor: effects.actionCursor,
                      onPressed: () => _startDockerEdit(index, entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 18),
                      color: colorScheme.error,
                      tooltip: 'Eliminar',
                      mouseCursor: effects.actionCursor,
                      onPressed: () {
                        final newList = List<ApiDockerServiceEntry>.from(
                          options.apiDockerServices,
                        )..removeAt(index);
                        _saveOptions(
                          options.copyWith(apiDockerServices: newList),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _textEntryField(
                  controller: _dockerNombreCtrl,
                  decoration: _fieldDecoration(
                    label: 'Servicio',
                    hint: 'Nueva opción...',
                    helper: 'Campo requerido',
                  ),
                  onSubmitted: (_) => _addDockerEntry(options),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addDockerEntry(options),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar',
                mouseCursor: effects.actionCursor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
