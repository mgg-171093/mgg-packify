import 'package:flutter/material.dart';

/// Modal dialog shown when a new app version is available.
///
/// Shows version info, release notes, and a download progress indicator.
/// - "Actualizar ahora" triggers [onDownload] and shows a [LinearProgressIndicator].
/// - "Ignorar por ahora" closes the dialog.
/// - If download fails (progress == -1.0), shows error message + "Reintentar" button.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.onDownload,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final Future<void> Function({
    required void Function(double progress) onProgress,
  })
  onDownload;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  /// null = not started; -1.0 = error; 0.0..1.0 = downloading
  double? _progress;
  bool _isDownloading = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });
    await widget.onDownload(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = _progress == -1.0;

    return AlertDialog(
      title: const Text('Nueva versión disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versión actual: ${widget.currentVersion}'),
          Text(
            'Nueva versión: ${widget.latestVersion}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(widget.releaseNotes, style: theme.textTheme.bodySmall),
          ],
          if (_isDownloading && !isError) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_progress != null && _progress! > 0) ? _progress : null,
            ),
            const SizedBox(height: 4),
            Text(
              (_progress != null && _progress! > 0)
                  ? '${(_progress! * 100).toStringAsFixed(0)}%'
                  : 'Descargando...',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (isError) ...[
            const SizedBox(height: 12),
            Text(
              'Error al descargar. Verificá tu conexión.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading || isError)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ignorar por ahora'),
          ),
        if (isError)
          FilledButton(
            onPressed: _startDownload,
            child: const Text('Reintentar'),
          )
        else
          FilledButton(
            onPressed: _isDownloading ? null : _startDownload,
            child: const Text('Actualizar ahora'),
          ),
      ],
    );
  }
}
