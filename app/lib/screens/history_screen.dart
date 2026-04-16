import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/package_history_entry.dart';
import '../providers/history_provider.dart';
import '../providers/package_form_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          historyAsync.whenOrNull(
                data: (entries) => entries.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        tooltip: 'Limpiar historial',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Limpiar historial'),
                              content: const Text(
                                '¿Eliminar todo el historial de packages?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Limpiar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(historyProvider.notifier).clear();
                          }
                        },
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
        elevation: 1,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar historial: $e',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 72, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'No hay packages generados aún',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El historial aparecerá aquí después de generar packages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outlineVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final entry = entries[index];
              return Dismissible(
                key: ValueKey('${entry.packageName}_$index'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Eliminar entrada'),
                    content: Text(
                      '¿Eliminar "${entry.packageName}" del historial?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dCtx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dCtx).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  ref.read(historyProvider.notifier).delete(index);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                child: _HistoryEntryCard(
                  entry: entry,
                  onTap: () {
                    ref
                        .read(packageFormProvider.notifier)
                        .prefillFromHistory(entry);
                    context.go('/new-package');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _HistoryEntryCard
// ─────────────────────────────────────────────

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry, required this.onTap});

  final PackageHistoryEntry entry;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.packageName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.generatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(entry.ambiente),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
