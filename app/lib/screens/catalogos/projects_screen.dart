import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/options_model.dart';
import '../../providers/options_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key, this.returnTo});

  /// Route to navigate back to. Defaults to '/dashboard'.
  final String? returnTo;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _addCtrl = TextEditingController();

  // Inline-edit state
  int? _editingIndex;
  TextEditingController? _editCtrl;

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl?.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────

  void _startEdit(int index, ProjectEntry entry) {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = index;
      _editCtrl = TextEditingController(text: entry.name);
    });
  }

  void _cancelEdit() {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
  }

  void _confirmEdit(OptionsModel options) {
    final index = _editingIndex;
    if (index == null) return;
    final name = _editCtrl?.text.trim() ?? '';
    if (name.isEmpty) {
      _cancelEdit();
      return;
    }
    final newList = List<ProjectEntry>.from(options.projects);
    newList[index] = newList[index].copyWith(name: name);
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
    _save(options.copyWith(projects: newList));
  }

  void _add(OptionsModel options) {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    final newList = [
      ...options.projects,
      ProjectEntry(id: const Uuid().v4(), name: name),
    ];
    _addCtrl.clear();
    _save(options.copyWith(projects: newList));
  }

  void _delete(OptionsModel options, int index) {
    final newList = List<ProjectEntry>.from(options.projects)..removeAt(index);
    _save(options.copyWith(projects: newList));
  }

  void _save(OptionsModel options) {
    ref.read(optionsProvider.notifier).save(options);
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(optionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go(widget.returnTo ?? '/dashboard'),
        ),
        title: const Text('Proyectos'),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catálogo de proyectos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // ── Empty state ──────────────────────
              if (options.projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Sin proyectos configurados',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                // ── Project list ─────────────────────
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final entry = options.projects[index];

                    // Inline edit row
                    if (_editingIndex == index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Nombre del proyecto...',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _confirmEdit(options),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'Confirmar',
                            onPressed: () => _confirmEdit(options),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Cancelar',
                            onPressed: _cancelEdit,
                          ),
                        ],
                      );
                    }

                    // Display row
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar',
                          onPressed: () => _startEdit(index, entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined, size: 18),
                          color: Colors.red.shade400,
                          tooltip: 'Eliminar',
                          onPressed: () => _delete(options, index),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 8),

              // ── Add row ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nuevo proyecto...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _add(options),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _add(options),
                    icon: const Icon(Icons.add),
                    tooltip: 'Agregar proyecto',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
