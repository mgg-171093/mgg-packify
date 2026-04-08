import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/options_provider.dart';

// ─────────────────────────────────────────────
// Default texts for each doc section + field.
// These mirror the Python DOC_TEXT_DEFAULTS so we can show them as hints.
// ─────────────────────────────────────────────

const Map<String, Map<String, String>> kDocTextDefaults = {
  'doc': {
    'title': 'Manual de instalación',
    'section1_title': '1.- Componentes afectados:',
    'note_text':
        'Los componentes relacionados en este listado deberán ser respaldados y actualizados en caso de que existan, y en caso de no existir deberán ser agregados en la ruta especificada.',
    'section2_title': '2.- Proceso',
  },
  'sql': {
    'h2_title': '{seccion_num}.- SQL',
    'h3_subtitle':
        '{seccion_num}.1.- En la base de datos "{base_datos}" en el servidor de {ambiente}:',
    'step_execute': 'Ejecutar el script "{script}"',
  },
  'api_iis': {
    'h2_title': '{seccion_num}.- API',
    'h3_subtitle':
        '{seccion_num}.1.-  En el servidor de servicios en {ambiente}:',
    'step_update_service':
        'Actualizar el servicio "{api}" con el contenido del zip "{zip_name}"',
    'step_update_configs':
        'Actualizar las siguientes configuraciones en el archivo de configuración del servicio:',
    'step_deploy_jenkins': 'Hacer el despliegue CI/CD en Jenkins',
    'step_update_apim': 'Actualizar el schema del Api Management de AZURE',
  },
  'api_docker': {
    'h2_title': '{seccion_num}.- API',
    'h3_subtitle':
        '{seccion_num}.1.-  En el servidor de servicios en {ambiente}:',
    'step_update_service': 'Actualizar el servicio "{nombre}"',
    'step_deploy_jenkins': 'Hacer el despliegue CI/CD en Jenkins',
    'step_update_apim': 'Actualizar el schema del Api Management de AZURE',
    'step_update_env':
        'Actualizar las siguientes variables de entorno/configuración:',
  },
  'blob': {
    'h2_title': '{seccion_num}.- Blob Storage',
    'h3_subtitle':
        '{seccion_num}.1.-  En el servidor de Azure Blob Storage de {ambiente}:',
    'step_validate_folder':
        'Validar si existe la carpeta "{carpeta}" (si no existe, crearla)',
    'step_upload_files':
        'Dentro de la carpeta "{carpeta}" subir los siguientes archivos:',
    'step_generate_sas': 'Generar URL SAS',
  },
  'liferay_build': {
    'h2_title': '{seccion_num}.- Liferay',
    'h3_subtitle':
        '{seccion_num}.1.-  Hacer deploy de Liferay en ambiente {ambiente_display} la build # {build_id}',
  },
  'liferay': {
    'h2_title': '{seccion_num}.- Liferay',
    'h3_subtitle':
        '{seccion_num}.1.-  En el servidor de Liferay de {ambiente}:',
    'step_create_remote_app':
        'Crear (o actualizar) la Remote App "{nombre_app}" con los siguientes campos:',
    'step_go_site': 'Dirigirse al Sitio RETAIL → Páginas Privadas',
    'step_create_page': 'Crear la página "{pagina}"',
    'step_edit_page': 'Editar la página → pestaña Widgets / Remote Apps',
    'step_drag_widget': 'Arrastrar la Remote App "{widget}"',
    'step_publish': 'Dar clic en Publish',
  },
  'assets': {
    'h2_title': '{seccion_num}.- Assets (Liferay Documents and Media)',
    'h3_subtitle':
        '{seccion_num}.1.-  En el servidor de Liferay de {ambiente}:',
    'step_navigate': 'Dirigirse a Content & Data → Documents and Media',
    'step_upload': 'Subir el archivo "{asset}"',
  },
  'apim': {
    'h2_title': '{seccion_num}.- Azure API Management',
    'h3_subtitle': '{seccion_num}.1.-  En Azure API Management de {ambiente}:',
    'step_update_service': 'Actualizar el servicio "{svc}"',
  },
};

/// Tab configuration: display label → section key in kDocTextDefaults.
const _kTabs = [
  ('General', 'doc'),
  ('SQL', 'sql'),
  ('API IIS', 'api_iis'),
  ('API Docker', 'api_docker'),
  ('Blob Storage', 'blob'),
  ('Liferay Build', 'liferay_build'),
  ('Liferay', 'liferay'),
  ('Assets', 'assets'),
  ('APIM', 'apim'),
];

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

/// Converts snake_case keys to human-readable "Title Case Words".
String _keyToLabel(String key) {
  return key
      .split('_')
      .map(
        (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}

/// Extracts placeholder tokens (anything between {}) from a text string.
List<String> _extractPlaceholders(String text) {
  final regex = RegExp(r'\{([^}]+)\}');
  return regex.allMatches(text).map((m) => '{${m.group(1)!}}').toList();
}

// ─────────────────────────────────────────────
// DocTemplatesScreen
// ─────────────────────────────────────────────

class DocTemplatesScreen extends ConsumerStatefulWidget {
  const DocTemplatesScreen({super.key});

  @override
  ConsumerState<DocTemplatesScreen> createState() => _DocTemplatesScreenState();
}

class _DocTemplatesScreenState extends ConsumerState<DocTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTemplate(String section, String key, String? value) {
    final options = ref.read(optionsProvider).value;
    if (options == null) return;

    final current = Map<String, Map<String, String?>>.from(
      options.docTemplates.map(
        (k, v) => MapEntry(k, Map<String, String?>.from(v)),
      ),
    );

    final sectionMap = Map<String, String?>.from(current[section] ?? {});
    if (value == null) {
      sectionMap.remove(key);
    } else {
      sectionMap[key] = value;
    }

    // Clean up empty section maps
    if (sectionMap.isEmpty) {
      current.remove(section);
    } else {
      current[section] = sectionMap;
    }

    final updated = options.copyWith(docTemplates: current);
    ref.read(optionsProvider.notifier).save(updated);
  }

  void _resetSection(String section) {
    final options = ref.read(optionsProvider).value;
    if (options == null) return;

    final current = Map<String, Map<String, String?>>.from(
      options.docTemplates.map(
        (k, v) => MapEntry(k, Map<String, String?>.from(v)),
      ),
    );
    current.remove(section);

    final updated = options.copyWith(docTemplates: current);
    ref.read(optionsProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(optionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Texto de Documentos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _kTabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (options) => TabBarView(
          controller: _tabController,
          children: _kTabs.map((tab) {
            final tabLabel = tab.$1;
            final section = tab.$2;
            final defaults = kDocTextDefaults[section] ?? {};
            final overrides = options.docTemplates[section] ?? {};
            final hasOverrides = overrides.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section header with reset-all button ───────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tabLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (hasOverrides)
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Restablecer todo'),
                          onPressed: () => _resetSection(section),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Template rows ──────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: defaults.keys.map((key) {
                      final defaultText = defaults[key]!;
                      final currentValue =
                          overrides[key]; // null if not overridden
                      return _TemplateRow(
                        key: ValueKey('$section.$key'),
                        label: _keyToLabel(key),
                        defaultText: defaultText,
                        currentValue: currentValue,
                        onChanged: (value) =>
                            _updateTemplate(section, key, value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _TemplateRow — private widget for a single template field
// ─────────────────────────────────────────────

class _TemplateRow extends StatefulWidget {
  const _TemplateRow({
    super.key,
    required this.label,
    required this.defaultText,
    required this.currentValue,
    required this.onChanged,
  });

  final String label;
  final String defaultText;

  /// Null means "not overridden" (use Python default).
  final String? currentValue;

  final void Function(String? value) onChanged;

  @override
  State<_TemplateRow> createState() => _TemplateRowState();
}

class _TemplateRowState extends State<_TemplateRow> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_TemplateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller when parent passes a new currentValue (e.g. after reset).
    if (oldWidget.currentValue != widget.currentValue && !_focusNode.hasFocus) {
      _controller.text = widget.currentValue ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _save();
    }
  }

  void _save() {
    final raw = _controller.text.trim();
    final newValue = raw.isEmpty ? null : raw;
    if (newValue != widget.currentValue) {
      widget.onChanged(newValue);
    }
  }

  void _reset() {
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverridden = widget.currentValue != null;
    final placeholders = _extractPlaceholders(widget.defaultText);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row: label + reset button ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isOverridden
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isOverridden
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isOverridden)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    iconSize: 18,
                    tooltip: 'Restablecer a valor por defecto',
                    onPressed: _reset,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // ── TextField ─────────────────────────────────────────────
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.defaultText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withAlpha(153),
                  fontSize: 13,
                ),
                helperText: isOverridden
                    ? 'Personalizado'
                    : 'Usando texto por defecto',
                helperStyle: TextStyle(
                  color: isOverridden
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              onEditingComplete: _save,
            ),
            // ── Placeholders hint ─────────────────────────────────────
            if (placeholders.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Variables:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  ...placeholders.map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
