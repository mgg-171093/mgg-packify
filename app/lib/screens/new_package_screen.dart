import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_notifier/local_notifier.dart';
import '../core/api_client.dart';
import '../models/component_config.dart';
import '../models/generate_result.dart';
import '../models/options_model.dart';
import '../models/package_config.dart';
import '../models/package_history_entry.dart';
import '../models/package_template.dart';
import '../providers/history_provider.dart';
import '../providers/options_provider.dart';
import '../providers/package_form_provider.dart';
import '../providers/templates_provider.dart';
import '../widgets/component_detail_card.dart';
import '../widgets/component_selector.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/package_name_preview.dart';

class NewPackageScreen extends ConsumerStatefulWidget {
  const NewPackageScreen({super.key});

  @override
  ConsumerState<NewPackageScreen> createState() => _NewPackageScreenState();
}

class _NewPackageScreenState extends ConsumerState<NewPackageScreen> {
  final _formKey = GlobalKey<FormState>();

  // Local TextEditingControllers — synced to provider
  late TextEditingController _ticketCtrl;
  late TextEditingController _huNombreCtrl;
  late TextEditingController _iteracionCtrl;
  late TextEditingController _rutaCtrl;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _ticketCtrl = TextEditingController();
    _huNombreCtrl = TextEditingController();
    _iteracionCtrl = TextEditingController();
    _rutaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ticketCtrl.dispose();
    _huNombreCtrl.dispose();
    _iteracionCtrl.dispose();
    _rutaCtrl.dispose();
    super.dispose();
  }

  /// Sync controllers to provider state (called once on first build)
  void _initControllers(PackageFormState formState) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _ticketCtrl.text = formState.ticket;
    _huNombreCtrl.text = formState.huNombre;
    _iteracionCtrl.text = formState.iteracion;
    _rutaCtrl.text = formState.rutaPackages;
  }

  Future<void> _pickFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccioná la carpeta de packages',
      );
      if (result != null && mounted) {
        ref.read(packageFormProvider.notifier).updateRutaPackages(result);
        _rutaCtrl.text = result;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el selector de carpetas: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveTemplate(PackageFormState formState) async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar template'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del template',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final templateName = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (confirmed == true && templateName.isNotEmpty) {
      final template = PackageTemplate(
        name: templateName,
        selectedTypes: formState.selectedTypes.map((t) => t.key).toList(),
        instancesJson: const [],
      );
      await ref.read(templatesProvider.notifier).save(template);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Template guardado')));
      }
    }
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formState = ref.read(packageFormProvider);

    // Extra validation: at least one component selected
    if (formState.selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná al menos un componente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build step labels
    final List<String> steps = [
      'Creando estructura de carpetas',
      'Generando documento .docx',
    ];

    // Insert publish steps for api_iis instances with publicar == true
    final apiIisInstances = formState.instances[ComponentType.apiIis] ?? [];
    for (final inst in apiIisInstances) {
      if (inst.publicar) {
        final nombre = inst.nombreServicio.isNotEmpty
            ? inst.nombreServicio
            : 'servicio';
        steps.add('Publicando $nombre');
      }
    }

    steps.add('Guardando metadata');

    final config = PackageConfig(
      ticket: formState.ticket,
      huNombre: formState.huNombre,
      ambiente: formState.ambiente,
      iteracion: formState.iteracion,
      rutaPackages: formState.rutaPackages,
      projectName: formState.projectNombre,
      componentes: buildComponentes(
        formState.selectedTypes,
        formState.instances,
      ),
    );

    final generateFuture = ref.read(apiClientProvider).generatePackage(config);

    GenerateResult? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => GenerationProgressDialog(
        stepLabels: steps,
        generateFuture: generateFuture,
        onDone: (res) {
          result = res;
          Navigator.of(dialogCtx).pop(); // closes DIALOG only — NOT route
        },
      ),
    );

    if (mounted && result != null) {
      final res = result!;

      // F1: Save to history
      final entry = PackageHistoryEntry(
        ticket: formState.ticket,
        huNombre: formState.huNombre,
        ambiente: formState.ambiente,
        iteracion: formState.iteracion,
        packageName: res.packageName,
        packageDir: res.packageDir,
        generatedAt: DateTime.now(),
      );
      ref.read(historyProvider.notifier).add(entry);

      // F7: Windows toast notification (fire-and-forget)
      _sendToast(res.packageName);

      context.go('/success', extra: res);
    }
  }

  void _sendToast(String packageName) {
    try {
      final notification = LocalNotification(
        title: 'MGG-Packify',
        body: 'Package $packageName generado',
      );
      notification.show();
    } catch (_) {
      // toast is best-effort — ignore failures
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(packageFormProvider);
    final optionsAsync = ref.watch(optionsProvider);
    _initControllers(formState);

    final notifier = ref.read(packageFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // F3: Validation warnings
    final warnings = notifier.validationWarnings;

    // Project list from options
    final projects = optionsAsync.valueOrNull?.projects ?? [];
    final canGenerate = formState.projectNombre.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Package'),
        actions: [
          if (formState.selectedTypes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Guardar como template',
              onPressed: () => _saveTemplate(formState),
            ),
        ],
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sección 1: Datos del Package ──────────────
              _SectionHeader(
                title: 'Datos del Package',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              // Proyecto — must be the first field
              if (projects.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hay proyectos configurados. ',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(
                          '/catalogos/proyectos',
                          extra: '/new-package',
                        ),
                        child: Text(
                          'Configurar',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<ProjectEntry>(
                  decoration: const InputDecoration(
                    labelText: 'Proyecto *',
                    border: OutlineInputBorder(),
                  ),
                  value: projects
                      .where((p) => p.id == formState.projectId)
                      .firstOrNull,
                  hint: const Text('Seleccioná un proyecto'),
                  items: projects.map((p) {
                    return DropdownMenuItem<ProjectEntry>(
                      value: p,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) {
                      notifier.setProject(p.id, p.name);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _ticketCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ticket *',
                  hintText: 'MX01-274906',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El ticket es obligatorio'
                    : null,
                onChanged: notifier.updateTicket,
              ),
              const SizedBox(height: 16),

              // HU Nombre
              TextFormField(
                controller: _huNombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre HU / Fix / Spike',
                  hintText: 'Mejora login portal',
                  border: OutlineInputBorder(),
                ),
                onChanged: notifier.updateHuNombre,
              ),
              const SizedBox(height: 16),

              // Ambiente — SegmentedButton
              Row(
                children: [
                  const Text(
                    'Ambiente:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'QA', label: Text('QA')),
                      ButtonSegment(value: 'PROD', label: Text('PROD')),
                    ],
                    selected: {formState.ambiente},
                    onSelectionChanged: (selection) {
                      notifier.updateAmbiente(selection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Iteración
              TextFormField(
                controller: _iteracionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Iteración *',
                  hintText: '01',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La iteración es obligatoria'
                    : null,
                onChanged: notifier.updateIteracion,
              ),
              const SizedBox(height: 12),

              // Package Name Preview
              PackageNamePreview(
                ticket: formState.ticket,
                projectNombre: formState.projectNombre,
                ambiente: formState.ambiente,
                iteracion: formState.iteracion,
              ),
              const SizedBox(height: 16),

              // Ruta de packages
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rutaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de packages *',
                        hintText: 'C:\\Packages',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'La ruta es obligatoria'
                          : null,
                      onChanged: notifier.updateRutaPackages,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filled(
                      onPressed: _pickFolder,
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Seleccionar carpeta',
                    ),
                  ),
                ],
              ),

              // F3: Validation warning chips
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: warnings
                      .map(
                        (w) => Chip(
                          avatar: Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: colorScheme.onErrorContainer,
                          ),
                          label: Text(
                            w,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                          backgroundColor: colorScheme.errorContainer,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 32),

              // ── Sección 2: Componentes ─────────────────────
              _SectionHeader(
                title: 'Componentes',
                icon: Icons.widgets_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Seleccioná los componentes que incluye este package:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ComponentSelector(
                selectedTypes: formState.selectedTypes,
                onToggle: notifier.toggleComponent,
              ),
              const SizedBox(height: 32),

              // ── Sección 3: Detalle de componentes ──────────
              if (formState.selectedTypes.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Detalle de componentes',
                  icon: Icons.tune_outlined,
                ),
                const SizedBox(height: 12),
                // Render in canonical order
                for (final type in kCanonicalComponentOrder)
                  if (formState.selectedTypes.contains(type))
                    ComponentDetailCard(
                      key: ValueKey(type),
                      type: type,
                      instances: formState.instances[type] ?? [],
                      onAdd: () => notifier.addInstance(type),
                      onRemove: (idx) => notifier.removeInstance(type, idx),
                      onUpdate: (idx, updated) =>
                          notifier.updateInstance(type, idx, updated),
                      returnTo: '/new-package',
                    ),
                const SizedBox(height: 16),
              ],

              // ── Generate Button ────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const Key('generate_button'),
                  onPressed: canGenerate ? _generate : null,
                  icon: Icon(
                    Icons.rocket_launch_outlined,
                    color: canGenerate ? Colors.white : null,
                  ),
                  label: Text(
                    'Generar Package',
                    style: TextStyle(
                      color: canGenerate ? Colors.white : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canGenerate ? colorScheme.primary : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _SectionHeader
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}
