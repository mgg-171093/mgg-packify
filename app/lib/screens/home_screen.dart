import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/package_template.dart';
import '../providers/package_form_provider.dart';
import '../providers/templates_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo + header
                Center(
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      Widget logo = Image.asset(
                        'assets/logo-mgg.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      );
                      if (isDark) {
                        logo = ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          child: logo,
                        );
                      }
                      return logo;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MGG-Packify',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Portal Retail · Skandia México',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // "Nuevo Package" — primary
                _HomeActionButton(
                  label: 'Nuevo Package',
                  icon: Icons.add_box_outlined,
                  color: colorScheme.primary,
                  onTap: () => context.go('/new-package'),
                ),
                const SizedBox(height: 16),
                // "Clonar Package" — secondary
                _HomeActionButton(
                  label: 'Clonar Package',
                  icon: Icons.copy_outlined,
                  color: colorScheme.secondary,
                  onTap: () => context.go('/clone'),
                ),
                const SizedBox(height: 16),
                // "Historial"
                _HomeActionButton(
                  label: 'Historial',
                  icon: Icons.history_outlined,
                  color: colorScheme.tertiary,
                  onTap: () => context.go('/history'),
                ),
                const SizedBox(height: 16),
                // "Templates" — bottom sheet
                _HomeActionButton(
                  label: 'Templates',
                  icon: Icons.bookmark_outline,
                  color: colorScheme.tertiary,
                  onTap: () => _showTemplatesSheet(context, ref),
                ),
                const SizedBox(height: 16),
                // "Configuración" — surface variant
                _HomeActionButton(
                  label: 'Configuración',
                  icon: Icons.settings_outlined,
                  color: colorScheme.onSurfaceVariant,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplatesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) =>
          _TemplatesSheet(onApply: () => context.go('/new-package')),
    );
  }
}

// ─────────────────────────────────────────────
// _HomeActionButton
// ─────────────────────────────────────────────

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _TemplatesSheet
// ─────────────────────────────────────────────

class _TemplatesSheet extends ConsumerWidget {
  const _TemplatesSheet({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final templatesAsync = ref.watch(templatesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.bookmark_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Templates guardados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (templates) {
                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 48,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay templates guardados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Guardá un template desde "Nuevo Package"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final tpl = templates[i];
                    return _TemplateCard(
                      template: tpl,
                      onApply: () {
                        ref
                            .read(packageFormProvider.notifier)
                            .applyTemplate(tpl);
                        Navigator.of(context).pop();
                        onApply();
                      },
                      onDelete: () =>
                          ref.read(templatesProvider.notifier).delete(i),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onApply,
    required this.onDelete,
  });

  final PackageTemplate template;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.bookmark, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${template.selectedTypes.length} componentes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onApply, child: const Text('Aplicar')),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: colorScheme.error,
              ),
              tooltip: 'Eliminar template',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
