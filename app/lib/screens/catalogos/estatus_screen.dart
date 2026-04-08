import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/options_model.dart';
import '../../providers/options_provider.dart';
import '../../widgets/catalog_list_section.dart';

class EstatusScreen extends ConsumerWidget {
  const EstatusScreen({super.key, this.returnTo});

  /// Route to go back to (from state.extra). Defaults to '/dashboard'.
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
        title: const Text('Estatus'),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CatalogListSection(
            title: 'Estatus disponibles',
            items: options.estatusList,
            addHint: 'Nuevo estatus...',
            emptyMessage: 'Sin estatus configurados',
            onChanged: (updated) {
              final newOptions = options.copyWith(estatusList: updated);
              ref.read(optionsProvider.notifier).save(newOptions);
            },
          ),
        ),
      ),
    );
  }
}
