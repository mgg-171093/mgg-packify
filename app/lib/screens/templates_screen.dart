import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/package_template.dart';
import '../providers/package_form_provider.dart';
import '../providers/templates_provider.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay templates guardados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Guardá un template desde "Nuevo Package"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final tpl = templates[i];
              return _TemplateCard(
                template: tpl,
                onApply: () {
                  ref.read(packageFormProvider.notifier).applyTemplate(tpl);
                  context.go('/new-package');
                },
                onDelete: () => ref.read(templatesProvider.notifier).delete(i),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _TemplateCard
// ─────────────────────────────────────────────

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
