import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/options_provider.dart';
import '../../widgets/catalog_list_section.dart';

class BasesDatosScreen extends ConsumerWidget {
  const BasesDatosScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(optionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go(returnTo ?? '/dashboard'),
        ),
        title: const Text('Bases de Datos'),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CatalogListSection(
            title: 'Bases de datos SQL',
            items: options.sqlDatabases,
            addHint: 'Nombre de base de datos...',
            emptyMessage: 'Sin bases de datos configuradas',
            onChanged: (updated) {
              final newOptions = options.copyWith(sqlDatabases: updated);
              ref.read(optionsProvider.notifier).save(newOptions);
            },
          ),
        ),
      ),
    );
  }
}
