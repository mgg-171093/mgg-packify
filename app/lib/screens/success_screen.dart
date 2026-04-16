import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../models/generate_result.dart';
import '../providers/package_form_provider.dart';

class SuccessScreen extends ConsumerWidget {
  const SuccessScreen({super.key, required this.result});

  final GenerateResult result;

  Future<void> _openFolder(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final uri = Uri.file(result.packageDir);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir la carpeta: ${result.packageDir}'),
            backgroundColor: colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openSubfolder(BuildContext context, String subdir) async {
    final colorScheme = Theme.of(context).colorScheme;
    final path = p.join(result.packageDir, subdir);
    final dir = Directory(path);
    if (!dir.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carpeta no encontrada: $path'),
            backgroundColor: colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir: $path'),
            backgroundColor: colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openInVsCode(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final uri = Uri.parse('vscode://file/${result.packageDir}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo abrir VS Code'),
            backgroundColor: colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 3),
                    ),
                    child: Icon(
                      Icons.check,
                      color: colorScheme.primary,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  '¡Package generado!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Package name — primary, prominent
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    result.packageName,
                    key: ValueKey(result.packageName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // F5: Quick action chips
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Abrir en VS Code
                      ActionChip(
                        avatar: const Icon(Icons.code, size: 16),
                        label: const Text('Abrir en VS Code'),
                        onPressed: () => _openInVsCode(context),
                      ),
                      // Copiar nombre
                      ActionChip(
                        avatar: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar nombre'),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: result.packageName),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nombre copiado al portapapeles'),
                              duration: Duration(seconds: 2),
                              backgroundColor: colorScheme.primaryContainer,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      // Abrir SQL
                      ActionChip(
                        avatar: const Icon(Icons.storage, size: 16),
                        label: const Text('Abrir SQL'),
                        onPressed:
                            Directory(
                              p.join(result.packageDir, 'Componentes', 'SQL'),
                            ).existsSync()
                            ? () => _openSubfolder(
                                context,
                                p.join('Componentes', 'SQL'),
                              )
                            : null,
                      ),
                      // Abrir API
                      ActionChip(
                        avatar: const Icon(Icons.api, size: 16),
                        label: const Text('Abrir API'),
                        onPressed:
                            Directory(
                              p.join(result.packageDir, 'Componentes', 'API'),
                            ).existsSync()
                            ? () => _openSubfolder(
                                context,
                                p.join('Componentes', 'API'),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Package directory — tappable
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: InkWell(
                    onTap: () => _openFolder(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_open_outlined,
                            color: Colors.amber,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carpeta del package',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.packageDir,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Doc path
                if (result.docPath.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: colorScheme.secondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Documento generado',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.docPath,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 24),

                // Copy errors — only shown when non-empty
                if (result.copyErrors.isNotEmpty) ...[
                  Card(
                    color: colorScheme.secondaryContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ Errores de copia manual',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Los siguientes scripts deben copiarse manualmente:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final errMsg in result.copyErrors)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errMsg,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Buttons
                ElevatedButton.icon(
                  onPressed: () => _openFolder(context),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Abrir carpeta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(packageFormProvider.notifier).reset();
                    context.go('/new-package');
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Nuevo Package'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
