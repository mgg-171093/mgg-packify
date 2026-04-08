import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(optionsProvider);

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
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
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
                        child: TextField(
                          controller: _iisEditNombreCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Nombre...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _iisEditRutaCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ruta...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open_outlined),
                        tooltip: 'Seleccionar .csproj',
                        onPressed: () => _pickIisRuta(_iisEditRutaCtrl!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Confirmar',
                        onPressed: () => _confirmIisEdit(options),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Cancelar',
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar',
                      onPressed: () => _startIisEdit(index, entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 18),
                      color: Colors.red.shade400,
                      tooltip: 'Eliminar',
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
                child: TextField(
                  controller: _iisNombreCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nombre...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _addIisEntry(options),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _iisRutaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ruta...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _addIisEntry(options),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: 'Seleccionar .csproj',
                onPressed: () => _pickIisRuta(_iisRutaCtrl),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: () => _addIisEntry(options),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar',
                style: IconButton.styleFrom(
                  backgroundColor: null,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Docker Tab ───────────────────────────────

  Widget _buildDockerTab(OptionsModel options) {
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
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
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
                        child: TextField(
                          controller: _dockerEditNombreCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Nombre...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Confirmar',
                        onPressed: () => _confirmDockerEdit(options),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Cancelar',
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
                      onPressed: () => _startDockerEdit(index, entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 18),
                      color: Colors.red.shade400,
                      tooltip: 'Eliminar',
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
                child: TextField(
                  controller: _dockerNombreCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nueva opción...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _addDockerEntry(options),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addDockerEntry(options),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar',
                style: IconButton.styleFrom(
                  backgroundColor: null,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
