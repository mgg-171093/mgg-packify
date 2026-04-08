import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/package_history_entry.dart';
import '../providers/history_provider.dart';
import '../providers/options_provider.dart';
import '../providers/settings_provider.dart';

// ─────────────────────────────────────────────
// DashboardMetrics — pure data helper
// ─────────────────────────────────────────────

class DashboardMetrics {
  const DashboardMetrics(this._entries);

  final List<PackageHistoryEntry> _entries;

  int total() => _entries.length;

  int today() {
    final now = DateTime.now();
    return _entries
        .where(
          (e) =>
              e.generatedAt.year == now.year &&
              e.generatedAt.month == now.month &&
              e.generatedAt.day == now.day,
        )
        .length;
  }

  int thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    return _entries.where((e) => e.generatedAt.isAfter(startOfWeek)).length;
  }

  int thisMonth() {
    final now = DateTime.now();
    return _entries
        .where(
          (e) =>
              e.generatedAt.year == now.year &&
              e.generatedAt.month == now.month,
        )
        .length;
  }

  Map<String, int> byAmbiente() {
    final map = <String, int>{};
    for (final e in _entries) {
      map[e.ambiente] = (map[e.ambiente] ?? 0) + 1;
    }
    return map;
  }

  List<PackageHistoryEntry> recent(int count) {
    return _entries.take(count).toList();
  }
}

// ─────────────────────────────────────────────
// DashboardScreen
// ─────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final optionsAsync = ref.watch(optionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (entries) {
          final metrics = DashboardMetrics(entries);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Metrics row ──────────────────────
                _SectionTitle(label: 'Resumen'),
                const SizedBox(height: 12),
                _MetricsRow(metrics: metrics),
                const SizedBox(height: 24),

                // ── Por ambiente ─────────────────────
                if (metrics.total() > 0) ...[
                  _SectionTitle(label: 'Por ambiente'),
                  const SizedBox(height: 12),
                  _AmbienteBreakdown(byAmbiente: metrics.byAmbiente()),
                  const SizedBox(height: 24),
                ],

                // ── Config status ────────────────────
                _SectionTitle(label: 'Estado de configuración'),
                const SizedBox(height: 12),
                settingsAsync.when(
                  loading: () => const _ConfigStatusCard(
                    qaConfigured: false,
                    prodConfigured: false,
                    loading: true,
                  ),
                  error: (_, __) => const _ConfigStatusCard(
                    qaConfigured: false,
                    prodConfigured: false,
                    loading: false,
                  ),
                  data: (settings) => _ConfigStatusCard(
                    qaConfigured: settings.qa.api.isNotEmpty,
                    prodConfigured: settings.prod.api.isNotEmpty,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Catalog counters ─────────────────
                _SectionTitle(label: 'Catálogos'),
                const SizedBox(height: 12),
                optionsAsync.when(
                  loading: () => const _CatalogCountsCard(
                    estatus: 0,
                    tiposSql: 0,
                    tiposBlob: 0,
                    serviciosIis: 0,
                    serviciosDocker: 0,
                    basesDatos: 0,
                    loading: true,
                  ),
                  error: (_, __) => const _CatalogCountsCard(
                    estatus: 0,
                    tiposSql: 0,
                    tiposBlob: 0,
                    serviciosIis: 0,
                    serviciosDocker: 0,
                    basesDatos: 0,
                  ),
                  data: (options) => _CatalogCountsCard(
                    estatus: options.estatusList.length,
                    tiposSql: options.tipoSqlList.length,
                    tiposBlob: options.tipoBlobList.length,
                    serviciosIis: options.apiIisServices.length,
                    serviciosDocker: options.apiDockerServices.length,
                    basesDatos: options.sqlDatabases.length,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Recent packages ──────────────────
                if (metrics.total() > 0) ...[
                  _SectionTitle(label: 'Últimos generados'),
                  const SizedBox(height: 12),
                  ...metrics
                      .recent(5)
                      .map(
                        (e) => _RecentPackageCard(
                          entry: e,
                          onTap: () => context.go('/history'),
                        ),
                      ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no generaste ningún package',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/new-package'),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('Nuevo Package'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _SectionTitle
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _MetricsRow — total / hoy / semana / mes
// ─────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(label: 'Total', value: metrics.total()),
        _MetricCard(label: 'Hoy', value: metrics.today()),
        _MetricCard(label: 'Esta semana', value: metrics.thisWeek()),
        _MetricCard(label: 'Este mes', value: metrics.thisMonth()),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _AmbienteBreakdown
// ─────────────────────────────────────────────

class _AmbienteBreakdown extends StatelessWidget {
  const _AmbienteBreakdown({required this.byAmbiente});

  final Map<String, int> byAmbiente;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (byAmbiente.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: byAmbiente.entries.map((e) {
        return Chip(
          label: Text('${e.key}: ${e.value}'),
          backgroundColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// _ConfigStatusCard
// ─────────────────────────────────────────────

class _ConfigStatusCard extends StatelessWidget {
  const _ConfigStatusCard({
    required this.qaConfigured,
    required this.prodConfigured,
    this.loading = false,
  });

  final bool qaConfigured;
  final bool prodConfigured;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ConfigRow(label: 'Servidores QA', configured: qaConfigured),
            const SizedBox(height: 8),
            _ConfigRow(label: 'Servidores PROD', configured: prodConfigured),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.configured});

  final String label;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          configured
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          size: 18,
          color: configured ? colorScheme.primary : colorScheme.error,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(
          configured ? 'Configurado' : 'Sin configurar',
          style: TextStyle(
            fontSize: 12,
            color: configured
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _CatalogCountsCard
// ─────────────────────────────────────────────

class _CatalogCountsCard extends StatelessWidget {
  const _CatalogCountsCard({
    required this.estatus,
    required this.tiposSql,
    required this.tiposBlob,
    required this.serviciosIis,
    required this.serviciosDocker,
    required this.basesDatos,
    this.loading = false,
  });

  final int estatus;
  final int tiposSql;
  final int tiposBlob;
  final int serviciosIis;
  final int serviciosDocker;
  final int basesDatos;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _CatalogCount(label: 'Estatus', count: estatus),
            _CatalogCount(label: 'Tipos SQL', count: tiposSql),
            _CatalogCount(label: 'Tipos Blob', count: tiposBlob),
            _CatalogCount(label: 'Servicios IIS', count: serviciosIis),
            _CatalogCount(label: 'Servicios Docker', count: serviciosDocker),
            _CatalogCount(label: 'Bases de datos', count: basesDatos),
          ],
        ),
      ),
    );
  }
}

class _CatalogCount extends StatelessWidget {
  const _CatalogCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _RecentPackageCard
// ─────────────────────────────────────────────

class _RecentPackageCard extends StatelessWidget {
  const _RecentPackageCard({required this.entry, required this.onTap});

  final PackageHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: colorScheme.primary,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      entry.ticket,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  entry.ambiente,
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
