import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PackageNamePreview extends StatelessWidget {
  const PackageNamePreview({
    super.key,
    required this.ticket,
    required this.projectNombre,
    required this.ambiente,
    required this.iteracion,
  });

  final String ticket;
  final String projectNombre;
  final String ambiente;
  final String iteracion;

  String get _previewName {
    final t = ticket.isEmpty ? '---' : ticket;
    final p = projectNombre.isEmpty ? '---' : projectNombre;
    final a = ambiente.isEmpty ? '---' : ambiente;
    final i = iteracion.isEmpty ? '--' : iteracion.padLeft(2, '0');
    return '$t-${p}_$a-$i';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = _previewName;

    return Card(
      color: colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.label_outline, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  name,
                  key: ValueKey(name),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              tooltip: 'Copiar nombre',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: name));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nombre copiado'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
