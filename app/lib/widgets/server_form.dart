import 'package:flutter/material.dart';
import '../models/component_config.dart';
import '../models/package_config.dart';

class ServerForm extends StatefulWidget {
  const ServerForm({
    super.key,
    required this.selectedTypes,
    required this.serverConfig,
    required this.onChanged,
  });

  final Set<ComponentType> selectedTypes;
  final ServerConfig serverConfig;
  final void Function(ServerConfig) onChanged;

  @override
  State<ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<ServerForm> {
  late TextEditingController _apiCtrl;
  late TextEditingController _bdCtrl;
  late TextEditingController _blobCtrl;
  late TextEditingController _liferayCtrl;

  @override
  void initState() {
    super.initState();
    _apiCtrl = TextEditingController(text: widget.serverConfig.api);
    _bdCtrl = TextEditingController(text: widget.serverConfig.bd);
    _blobCtrl = TextEditingController(text: widget.serverConfig.blob);
    _liferayCtrl = TextEditingController(text: widget.serverConfig.liferay);
  }

  @override
  void didUpdateWidget(ServerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if parent changed the config (e.g. prefill from settings)
    if (oldWidget.serverConfig != widget.serverConfig) {
      _apiCtrl.text = widget.serverConfig.api;
      _bdCtrl.text = widget.serverConfig.bd;
      _blobCtrl.text = widget.serverConfig.blob;
      _liferayCtrl.text = widget.serverConfig.liferay;
    }
  }

  @override
  void dispose() {
    _apiCtrl.dispose();
    _bdCtrl.dispose();
    _blobCtrl.dispose();
    _liferayCtrl.dispose();
    super.dispose();
  }

  bool get _showApi =>
      widget.selectedTypes.contains(ComponentType.apiIis) ||
      widget.selectedTypes.contains(ComponentType.apiDocker);

  bool get _showBd => widget.selectedTypes.contains(ComponentType.sql);

  bool get _showBlob => widget.selectedTypes.contains(ComponentType.blob);

  bool get _showLiferay =>
      widget.selectedTypes.contains(ComponentType.liferay) ||
      widget.selectedTypes.contains(ComponentType.assets);

  void _notify() {
    widget.onChanged(
      ServerConfig(
        api: _apiCtrl.text,
        bd: _bdCtrl.text,
        blob: _blobCtrl.text,
        liferay: _liferayCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasAny = _showApi || _showBd || _showBlob || _showLiferay;
    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Seleccioná al menos un componente para ver los campos de servidor.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showApi) ...[
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextField(
              controller: _apiCtrl,
              decoration: const InputDecoration(
                labelText: 'Servidor de servicios/APIs',
                hintText: '10.42.55.25',
                helperText: 'Se aplica a API IIS, Docker y APIM',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_showBd) ...[
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextField(
              controller: _bdCtrl,
              decoration: const InputDecoration(
                labelText: 'Servidor de base de datos',
                hintText: '10.42.55.26',
                helperText: 'Se aplica a componentes SQL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_showBlob) ...[
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextField(
              controller: _blobCtrl,
              decoration: const InputDecoration(
                labelText: 'Azure Blob Storage (URL o cuenta)',
                hintText: 'mystorageaccount.blob.core.windows.net',
                helperText: 'Se aplica a componentes Blob',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_showLiferay) ...[
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextField(
              controller: _liferayCtrl,
              decoration: const InputDecoration(
                labelText: 'Servidor Liferay',
                hintText: '10.42.55.27',
                helperText: 'Se aplica a Liferay y Assets',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
        ],
      ],
    );
  }
}
