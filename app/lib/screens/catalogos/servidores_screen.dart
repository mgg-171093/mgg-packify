import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/settings_model.dart';
import '../../providers/settings_provider.dart';

class ServidoresScreen extends ConsumerStatefulWidget {
  const ServidoresScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<ServidoresScreen> createState() => _ServidoresScreenState();
}

class _ServidoresScreenState extends ConsumerState<ServidoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // QA controllers
  late TextEditingController _qaApiCtrl;
  late TextEditingController _qaBdCtrl;
  late TextEditingController _qaBlobCtrl;
  late TextEditingController _qaLiferayCtrl;

  // PROD controllers
  late TextEditingController _prodApiCtrl;
  late TextEditingController _prodBdCtrl;
  late TextEditingController _prodBlobCtrl;
  late TextEditingController _prodLiferayCtrl;

  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _qaApiCtrl = TextEditingController();
    _qaBdCtrl = TextEditingController();
    _qaBlobCtrl = TextEditingController();
    _qaLiferayCtrl = TextEditingController();
    _prodApiCtrl = TextEditingController();
    _prodBdCtrl = TextEditingController();
    _prodBlobCtrl = TextEditingController();
    _prodLiferayCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qaApiCtrl.dispose();
    _qaBdCtrl.dispose();
    _qaBlobCtrl.dispose();
    _qaLiferayCtrl.dispose();
    _prodApiCtrl.dispose();
    _prodBdCtrl.dispose();
    _prodBlobCtrl.dispose();
    _prodLiferayCtrl.dispose();
    super.dispose();
  }

  void _populate(SettingsModel settings) {
    _qaApiCtrl.text = settings.qa.api;
    _qaBdCtrl.text = settings.qa.bd;
    _qaBlobCtrl.text = settings.qa.blob;
    _qaLiferayCtrl.text = settings.qa.liferay;
    _prodApiCtrl.text = settings.prod.api;
    _prodBdCtrl.text = settings.prod.bd;
    _prodBlobCtrl.text = settings.prod.blob;
    _prodLiferayCtrl.text = settings.prod.liferay;
    _populated = true;
  }

  SettingsModel _buildCurrentModel() {
    return SettingsModel(
      qa: ServerConfigModel(
        api: _qaApiCtrl.text,
        bd: _qaBdCtrl.text,
        blob: _qaBlobCtrl.text,
        liferay: _qaLiferayCtrl.text,
      ),
      prod: ServerConfigModel(
        api: _prodApiCtrl.text,
        bd: _prodBdCtrl.text,
        blob: _prodBlobCtrl.text,
        liferay: _prodLiferayCtrl.text,
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(settingsProvider.notifier).save(_buildCurrentModel());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _clearAll() {
    ref.read(settingsProvider.notifier).clear();
    _populate(SettingsModel.empty());
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración limpiada')));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    settingsAsync.whenData((settings) {
      if (!_populated) _populate(settings);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go(widget.returnTo ?? '/dashboard'),
        ),
        title: const Text('Servidores'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'QA'),
            Tab(text: 'PROD'),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: $e')),
        data: (_) => Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ServerTab(
                    label: 'QA',
                    apiCtrl: _qaApiCtrl,
                    bdCtrl: _qaBdCtrl,
                    blobCtrl: _qaBlobCtrl,
                    liferayCtrl: _qaLiferayCtrl,
                  ),
                  _ServerTab(
                    label: 'PROD',
                    apiCtrl: _prodApiCtrl,
                    bdCtrl: _prodBdCtrl,
                    blobCtrl: _prodBlobCtrl,
                    liferayCtrl: _prodLiferayCtrl,
                  ),
                ],
              ),
            ),
            _ActionBar(onSave: _save, onClear: _clearAll),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ServerTab
// ─────────────────────────────────────────────

class _ServerTab extends StatelessWidget {
  const _ServerTab({
    required this.label,
    required this.apiCtrl,
    required this.bdCtrl,
    required this.blobCtrl,
    required this.liferayCtrl,
  });

  final String label;
  final TextEditingController apiCtrl;
  final TextEditingController bdCtrl;
  final TextEditingController blobCtrl;
  final TextEditingController liferayCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Servidores $label',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _ServerField(
            controller: apiCtrl,
            label: 'API / Servicios',
            hint: '10.42.55.25',
            icon: Icons.api_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: bdCtrl,
            label: 'Base de datos',
            hint: '10.42.55.26',
            icon: Icons.storage_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: blobCtrl,
            label: 'Azure Blob Storage',
            hint: 'mystorageaccount.blob.core.windows.net',
            icon: Icons.cloud_outlined,
          ),
          const SizedBox(height: 16),
          _ServerField(
            controller: liferayCtrl,
            label: 'Liferay',
            hint: '10.42.55.27',
            icon: Icons.web_outlined,
          ),
        ],
      ),
    );
  }
}

class _ServerField extends StatelessWidget {
  const _ServerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ActionBar
// ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onSave, required this.onClear});

  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Limpiar todo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: null),
          ),
        ],
      ),
    );
  }
}
