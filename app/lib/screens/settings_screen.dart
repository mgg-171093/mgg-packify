import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/options_model.dart';
import '../models/settings_model.dart';
import '../providers/options_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_mode_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // QA controllers
  late TextEditingController _qaApiCtrl;
  late TextEditingController _qaBdCtrl;
  late TextEditingController _qaBlobCtrl;
  late TextEditingController _qaLiferayCtrl;

  // PROD controllers
  late TextEditingController _prodApiCtrl;
  late TextEditingController _prodBdCtrl;
  late TextEditingController _prodBlobCtrl;
  late TextEditingController _prodLiferayCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _qaApiCtrl = TextEditingController();
    _qaBdCtrl = TextEditingController();
    _qaBlobCtrl = TextEditingController();
    _qaLiferayCtrl = TextEditingController();
    _prodApiCtrl = TextEditingController();
    _prodBdCtrl = TextEditingController();
    _prodBlobCtrl = TextEditingController();
    _prodLiferayCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qaApiCtrl.dispose();
    _qaBdCtrl.dispose();
    _qaBlobCtrl.dispose();
    _qaLiferayCtrl.dispose();
    _prodApiCtrl.dispose();
    _prodBdCtrl.dispose();
    _prodBlobCtrl.dispose();
    _prodLiferayCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(SettingsModel settings) {
    _qaApiCtrl.text = settings.qa.api;
    _qaBdCtrl.text = settings.qa.bd;
    _qaBlobCtrl.text = settings.qa.blob;
    _qaLiferayCtrl.text = settings.qa.liferay;
    _prodApiCtrl.text = settings.prod.api;
    _prodBdCtrl.text = settings.prod.bd;
    _prodBlobCtrl.text = settings.prod.blob;
    _prodLiferayCtrl.text = settings.prod.liferay;
  }

  SettingsModel _buildCurrentModel() {
    return SettingsModel(
      qa: ServerConfigModel(
        api: _qaApiCtrl.text,
        bd: _qaBdCtrl.text,
        blob: _qaBlobCtrl.text,
        liferay: _qaLiferayCtrl.text,
      ),
      prod: ServerConfigModel(
        api: _prodApiCtrl.text,
        bd: _prodBdCtrl.text,
        blob: _prodBlobCtrl.text,
        liferay: _prodLiferayCtrl.text,
      ),
    );
  }

  Future<void> _save() async {
    try {
      final model = _buildCurrentModel();
      await ref.read(settingsProvider.notifier).save(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _clearAll() {
    ref.read(settingsProvider.notifier).clear();
    _populateControllers(SettingsModel.empty());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración limpiada')));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final optionsAsync = ref.watch(optionsProvider);

    // Populate controllers once when data loads
    settingsAsync.whenData((settings) {
      // Only populate if controllers are empty (first load)
      if (_qaApiCtrl.text.isEmpty && settings.qa.api.isNotEmpty) {
        _populateControllers(settings);
      } else if (_qaApiCtrl.text.isEmpty) {
        _populateControllers(settings);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
          tooltip: 'Volver',
        ),
        title: const Text('Configuración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Servidores QA'),
            Tab(text: 'Servidores PROD'),
            Tab(text: 'Opciones'),
            Tab(text: 'Servicios API'),
            Tab(text: 'Apariencia'),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (_) => Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ServerTab(
                    label: 'QA',
                    apiCtrl: _qaApiCtrl,
                    bdCtrl: _qaBdCtrl,
                    blobCtrl: _qaBlobCtrl,
                    liferayCtrl: _qaLiferayCtrl,
                  ),
                  _ServerTab(
                    label: 'PROD',
                    apiCtrl: _prodApiCtrl,
                    bdCtrl: _prodBdCtrl,
                    blobCtrl: _prodBlobCtrl,
                    liferayCtrl: _prodLiferayCtrl,
                  ),
                  _OptionsTab(
                    optionsAsync: optionsAsync,
                    onChanged: (updated) =>
                        ref.read(optionsProvider.notifier).save(updated),
                  ),
                  _ServiciosApiTab(
                    optionsAsync: optionsAsync,
                    onChanged: (updated) =>
                        ref.read(optionsProvider.notifier).save(updated),
                  ),
                  const _AppearanceTab(),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index >= 2) return const SizedBox.shrink();
                return _ActionBar(onSave: _save, onClear: _clearAll);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ServerTab
// ─────────────────────────────────────────────

class _ServerTab extends StatelessWidget {
  const _ServerTab({
    required this.label,
    required this.apiCtrl,
    required this.bdCtrl,
    required this.blobCtrl,
    required this.liferayCtrl,
  });

  final String label;
  final TextEditingController apiCtrl;
  final TextEditingController bdCtrl;
  final TextEditingController blobCtrl;
  final TextEditingController liferayCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Servidores $label',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _ServerField(
            controller: apiCtrl,
            label: 'API / Servicios',
            hint: '10.42.55.25',
            icon: Icons.api_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: bdCtrl,
            label: 'Base de datos',
            hint: '10.42.55.26',
            icon: Icons.storage_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: blobCtrl,
            label: 'Azure Blob Storage',
            hint: 'mystorageaccount.blob.core.windows.net',
            icon: Icons.cloud_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: liferayCtrl,
            label: 'Liferay',
            hint: '10.42.55.27',
            icon: Icons.web_outlined,
          ),
        ],
      ),
    );
  }
}

class _ServerField extends StatelessWidget {
  const _ServerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ActionBar
// ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onSave, required this.onClear});

  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Limpiar todo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _OptionsTab
// ─────────────────────────────────────────────

class _OptionsTab extends StatefulWidget {
  const _OptionsTab({required this.optionsAsync, required this.onChanged});

  final AsyncValue<OptionsModel> optionsAsync;
  final void Function(OptionsModel updated) onChanged;

  @override
  State<_OptionsTab> createState() => _OptionsTabState();
}

class _OptionsTabState extends State<_OptionsTab> {
  final TextEditingController _estatusCtrl = TextEditingController();
  final TextEditingController _tipoSqlCtrl = TextEditingController();
  final TextEditingController _tipoBlobCtrl = TextEditingController();
  final TextEditingController _sqlDatabasesCtrl = TextEditingController();

  @override
  void dispose() {
    _estatusCtrl.dispose();
    _tipoSqlCtrl.dispose();
    _tipoBlobCtrl.dispose();
    _sqlDatabasesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.optionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar opciones: $e')),
      data: (options) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionListSection(
              title: 'Estatus',
              items: options.estatusList,
              controller: _estatusCtrl,
              onAdd: (value) {
                if (value.trim().isEmpty) return;
                final updated = options.copyWith(
                  estatusList: [...options.estatusList, value.trim()],
                );
                _estatusCtrl.clear();
                widget.onChanged(updated);
              },
              onRemove: (index) {
                final newList = List<String>.from(options.estatusList)
                  ..removeAt(index);
                widget.onChanged(options.copyWith(estatusList: newList));
              },
              onEdit: (i, val) {
                final updated = List<String>.from(options.estatusList);
                updated[i] = val;
                widget.onChanged(options.copyWith(estatusList: updated));
              },
            ),
            const SizedBox(height: 24),
            _OptionListSection(
              title: 'Tipo SQL',
              items: options.tipoSqlList,
              controller: _tipoSqlCtrl,
              onAdd: (value) {
                if (value.trim().isEmpty) return;
                final updated = options.copyWith(
                  tipoSqlList: [...options.tipoSqlList, value.trim()],
                );
                _tipoSqlCtrl.clear();
                widget.onChanged(updated);
              },
              onRemove: (index) {
                final newList = List<String>.from(options.tipoSqlList)
                  ..removeAt(index);
                widget.onChanged(options.copyWith(tipoSqlList: newList));
              },
              onEdit: (i, val) {
                final updated = List<String>.from(options.tipoSqlList);
                updated[i] = val;
                widget.onChanged(options.copyWith(tipoSqlList: updated));
              },
            ),
            const SizedBox(height: 24),
            _OptionListSection(
              title: 'Tipo Blob',
              items: options.tipoBlobList,
              controller: _tipoBlobCtrl,
              onAdd: (value) {
                if (value.trim().isEmpty) return;
                final updated = options.copyWith(
                  tipoBlobList: [...options.tipoBlobList, value.trim()],
                );
                _tipoBlobCtrl.clear();
                widget.onChanged(updated);
              },
              onRemove: (index) {
                final newList = List<String>.from(options.tipoBlobList)
                  ..removeAt(index);
                widget.onChanged(options.copyWith(tipoBlobList: newList));
              },
              onEdit: (i, val) {
                final updated = List<String>.from(options.tipoBlobList);
                updated[i] = val;
                widget.onChanged(options.copyWith(tipoBlobList: updated));
              },
            ),
            const SizedBox(height: 24),
            _OptionListSection(
              title: 'Bases de Datos',
              items: options.sqlDatabases,
              controller: _sqlDatabasesCtrl,
              onAdd: (value) {
                if (value.trim().isEmpty) return;
                final updated = options.copyWith(
                  sqlDatabases: [...options.sqlDatabases, value.trim()],
                );
                _sqlDatabasesCtrl.clear();
                widget.onChanged(updated);
              },
              onRemove: (index) {
                final newList = List<String>.from(options.sqlDatabases)
                  ..removeAt(index);
                widget.onChanged(options.copyWith(sqlDatabases: newList));
              },
              onEdit: (i, val) {
                final updated = List<String>.from(options.sqlDatabases);
                updated[i] = val;
                widget.onChanged(options.copyWith(sqlDatabases: updated));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ServiciosApiTab
// ─────────────────────────────────────────────

class _ServiciosApiTab extends StatefulWidget {
  const _ServiciosApiTab({required this.optionsAsync, required this.onChanged});

  final AsyncValue<OptionsModel> optionsAsync;
  final void Function(OptionsModel updated) onChanged;

  @override
  State<_ServiciosApiTab> createState() => _ServiciosApiTabState();
}

class _ServiciosApiTabState extends State<_ServiciosApiTab> {
  // Add-row controllers
  final TextEditingController _iisNombreCtrl = TextEditingController();
  final TextEditingController _iisRutaCtrl = TextEditingController();
  final TextEditingController _dockerNombreCtrl = TextEditingController();

  // IIS inline-edit state
  int? _iisEditingIndex;
  TextEditingController? _iisEditNombreCtrl;
  TextEditingController? _iisEditRutaCtrl;

  // Docker inline-edit state
  int? _dockerEditingIndex;
  TextEditingController? _dockerEditNombreCtrl;

  @override
  void dispose() {
    _iisNombreCtrl.dispose();
    _iisRutaCtrl.dispose();
    _dockerNombreCtrl.dispose();
    _iisEditNombreCtrl?.dispose();
    _iisEditRutaCtrl?.dispose();
    _dockerEditNombreCtrl?.dispose();
    super.dispose();
  }

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
    widget.onChanged(options.copyWith(apiIisServices: newList));
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
    widget.onChanged(options.copyWith(apiDockerServices: newList));
  }

  @override
  Widget build(BuildContext context) {
    return widget.optionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar opciones: $e')),
      data: (options) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Servicios IIS ──────────────────────
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
                    // ── Edit row ──
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
                  // ── Read-only row ──
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
                          widget.onChanged(
                            options.copyWith(apiIisServices: newList),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 8),
            // Add IIS row: nombre + ruta + picker
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

            const SizedBox(height: 24),

            // ── Servicios Docker ───────────────────
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
                    // ── Edit row ──
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
                  // ── Read-only row ──
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
                          widget.onChanged(
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
      ),
    );
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
    widget.onChanged(options.copyWith(apiIisServices: newList));
  }

  void _addDockerEntry(OptionsModel options) {
    final nombre = _dockerNombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final newList = [
      ...options.apiDockerServices,
      ApiDockerServiceEntry(nombre: nombre),
    ];
    _dockerNombreCtrl.clear();
    widget.onChanged(options.copyWith(apiDockerServices: newList));
  }
}

// ─────────────────────────────────────────────
// _OptionListSection
// ─────────────────────────────────────────────

class _OptionListSection extends StatefulWidget {
  const _OptionListSection({
    required this.title,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.onEdit,
  });

  final String title;
  final List<String> items;
  final TextEditingController controller;
  final void Function(String value) onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, String newValue)? onEdit;

  @override
  State<_OptionListSection> createState() => _OptionListSectionState();
}

class _OptionListSectionState extends State<_OptionListSection> {
  int? _editingIndex;
  TextEditingController? _editCtrl;

  @override
  void dispose() {
    _editCtrl?.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = index;
      _editCtrl = TextEditingController(text: widget.items[index]);
    });
  }

  void _confirmEdit() {
    final index = _editingIndex;
    if (index == null) return;
    final val = _editCtrl?.text.trim() ?? '';
    widget.onEdit?.call(index, val);
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
  }

  void _cancelEdit() {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Sin opciones',
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
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (_editingIndex == index) {
                // ── Edit row ──
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _editCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _confirmEdit(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Confirmar',
                      onPressed: _confirmEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Cancelar',
                      onPressed: _cancelEdit,
                    ),
                  ],
                );
              }
              // ── Read-only row ──
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.items[index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar',
                      onPressed: () => _startEdit(index),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outlined, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Eliminar',
                    onPressed: () => widget.onRemove(index),
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
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Nueva opción...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: widget.onAdd,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => widget.onAdd(widget.controller.text),
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
    );
  }
}

// ─────────────────────────────────────────────
// _AppearanceTab
// ─────────────────────────────────────────────

class _AppearanceTab extends ConsumerWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Oscuro'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (selection) {
              ref.read(themeModeProvider.notifier).setMode(selection.first);
            },
          ),
        ],
      ),
    );
  }
}
