import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/update_check_provider.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _apiVersion = '...';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadApiVersion();
  }

  Future<void> _loadApiVersion() async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _apiVersion = json['version'] as String? ?? 'N/A');
      } else {
        setState(() => _apiVersion = 'N/A');
      }
    } catch (_) {
      setState(() => _apiVersion = 'N/A');
    }
  }

  Future<void> _checkUpdates() async {
    setState(() => _checkingUpdate = true);
    await ref.read(updateCheckProvider.notifier).checkForUpdates();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    final state = ref.read(updateCheckProvider).valueOrNull;
    if (state?.hasUpdate == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nueva versión disponible: ${state!.latestVersion}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tenés la última versión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App icon + name ──────────────────────
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MGG Packify',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Generador de paquetes de instalación',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Version info ─────────────────────────
                    _InfoRow(
                      icon: Icons.phone_android_outlined,
                      label: 'Versión app',
                      value: kAppVersion,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.api_outlined,
                      label: 'Versión API',
                      value: _apiVersion,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── GitHub link ──────────────────────────
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Ver en GitHub'),
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://github.com/mgg-171093/mgg-packify',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // ── Check updates ─────────────────────────
                    ElevatedButton.icon(
                      icon: _checkingUpdate
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.system_update_alt, size: 16),
                      label: const Text('Buscar actualizaciones'),
                      onPressed: _checkingUpdate ? null : _checkUpdates,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _InfoRow
// ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
