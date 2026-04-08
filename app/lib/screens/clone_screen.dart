import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../models/package_list_item.dart';
import '../providers/clone_list_provider.dart';
import '../providers/package_form_provider.dart';
import '../providers/settings_provider.dart';

class CloneScreen extends ConsumerStatefulWidget {
  const CloneScreen({super.key});

  @override
  ConsumerState<CloneScreen> createState() => _CloneScreenState();
}

class _CloneScreenState extends ConsumerState<CloneScreen> {
  final _sourcePathCtrl = TextEditingController();
  final _iteracionCtrl = TextEditingController(text: '02');

  PackageListItem? _selectedPackage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _sourcePathCtrl.dispose();
    _iteracionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccioná el package a clonar',
    );
    if (result != null && mounted) {
      setState(() {
        _sourcePathCtrl.text = result;
        _selectedPackage = null;
      });
    }
  }

  String get _effectivePath =>
      _selectedPackage?.path ?? _sourcePathCtrl.text.trim();

  Future<void> _continue() async {
    final sourcePath = _effectivePath;
    if (sourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná o ingresá el path del package a clonar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newIteracion = _iteracionCtrl.text.trim();
    if (newIteracion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La iteración es obligatoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = await ref
          .read(apiClientProvider)
          .clonePackage(sourcePath, newIteracion);
      if (mounted) {
        ref.read(packageFormProvider.notifier).prefill(data);
        context.go('/new-package');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al clonar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final lastUsedPath = settings?.lastUsed?.rutaPackages ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clonar Package'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Opción A: Manual path ──────────────────
            Text(
              'Opción A — Buscar manualmente',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourcePathCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ruta del package',
                      hintText: 'C:\\Packages\\MX01-274906-PortalRetail_QA-01',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() => _selectedPackage = null),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _pickFolder,
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Examinar',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),

            // ── Opción B: List from settings ──────────
            if (lastUsedPath.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Opción B — Packages recientes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lastUsedPath,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              _PackageList(
                baseDir: lastUsedPath,
                selectedPath: _selectedPackage?.path,
                onSelect: (item) {
                  setState(() {
                    _selectedPackage = item;
                    _sourcePathCtrl.text = item.path;
                    // Auto-compute next iteracion from name
                    final name = item.name;
                    final iterMatch = RegExp(r'-(\d{2})$').firstMatch(name);
                    if (iterMatch != null) {
                      final currentIter =
                          int.tryParse(iterMatch.group(1) ?? '01') ?? 1;
                      _iteracionCtrl.text = (currentIter + 1)
                          .toString()
                          .padLeft(2, '0');
                    }
                  });
                },
              ),
            ],

            const SizedBox(height: 28),

            // ── Nueva iteración ────────────────────────
            TextField(
              controller: _iteracionCtrl,
              decoration: const InputDecoration(
                labelText: 'Nueva iteración *',
                hintText: '02',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Continue button ────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _continue,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Clonando...' : 'Continuar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _PackageList
// ─────────────────────────────────────────────

class _PackageList extends ConsumerWidget {
  const _PackageList({
    required this.baseDir,
    required this.selectedPath,
    required this.onSelect,
  });

  final String baseDir;
  final String? selectedPath;
  final void Function(PackageListItem) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(cloneListProvider(baseDir));

    return listAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(
        'Error al cargar lista: $e',
        style: const TextStyle(color: Colors.red),
      ),
      data: (packages) {
        if (packages.isEmpty) {
          return const Text(
            'No se encontraron packages en esta carpeta',
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          children: packages.map((pkg) {
            final isSelected = pkg.path == selectedPath;
            return Card(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : null,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => onSelect(pkg),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        pkg.hasMeta ? Icons.inventory_2 : Icons.folder,
                        color: pkg.hasMeta
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (pkg.createdAt != null)
                              Text(
                                _formatDate(pkg.createdAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (pkg.hasMeta)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
