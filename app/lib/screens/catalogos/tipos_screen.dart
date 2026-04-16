import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/options_provider.dart';
import '../../widgets/catalog_list_section.dart';

class TiposScreen extends ConsumerStatefulWidget {
  const TiposScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<TiposScreen> createState() => _TiposScreenState();
}

class _TiposScreenState extends ConsumerState<TiposScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Tipos'),
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
            Tab(text: 'SQL'),
            Tab(text: 'Blob'),
          ],
        ),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => TabBarView(
          controller: _tabController,
          children: [
            // ── SQL Tab ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: CatalogListSection(
                title: 'Tipos SQL',
                items: options.tipoSqlList,
                addHint: 'Nuevo tipo SQL...',
                emptyMessage: 'Sin tipos SQL configurados',
                onChanged: (updated) {
                  final newOptions = options.copyWith(tipoSqlList: updated);
                  ref.read(optionsProvider.notifier).save(newOptions);
                },
              ),
            ),
            // ── Blob Tab ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: CatalogListSection(
                title: 'Tipos Blob',
                items: options.tipoBlobList,
                addHint: 'Nuevo tipo Blob...',
                emptyMessage: 'Sin tipos Blob configurados',
                onChanged: (updated) {
                  final newOptions = options.copyWith(tipoBlobList: updated);
                  ref.read(optionsProvider.notifier).save(newOptions);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
