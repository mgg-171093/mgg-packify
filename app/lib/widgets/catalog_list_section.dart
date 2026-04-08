import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// CatalogListSection
// Generic CRUD list widget — add / inline-edit / delete
// Extracted from _OptionListSection in settings_screen.dart
// ─────────────────────────────────────────────

class CatalogListSection extends StatefulWidget {
  const CatalogListSection({
    super.key,
    required this.title,
    required this.items,
    required this.addHint,
    required this.onChanged,
    this.emptyMessage = 'Sin opciones',
    this.addLabel,
  });

  final String title;
  final List<String> items;

  /// Placeholder text for the add-new text field
  final String addHint;

  /// Label for the add button tooltip (optional)
  final String? addLabel;

  final String emptyMessage;

  /// Called whenever the list changes (add / edit / remove).
  /// Receives the NEW full list.
  final void Function(List<String> updated) onChanged;

  @override
  State<CatalogListSection> createState() => _CatalogListSectionState();
}

class _CatalogListSectionState extends State<CatalogListSection> {
  final TextEditingController _addCtrl = TextEditingController();

  int? _editingIndex;
  TextEditingController? _editCtrl;

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl?.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = index;
      _editCtrl = TextEditingController(text: widget.items[index]);
    });
  }

  void _confirmEdit() {
    final index = _editingIndex;
    if (index == null) return;
    final val = _editCtrl?.text.trim() ?? '';
    if (val.isNotEmpty) {
      final updated = List<String>.from(widget.items);
      updated[index] = val;
      widget.onChanged(updated);
    }
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
  }

  void _cancelEdit() {
    _editCtrl?.dispose();
    setState(() {
      _editingIndex = null;
      _editCtrl = null;
    });
  }

  void _add() {
    final val = _addCtrl.text.trim();
    if (val.isEmpty) return;
    final updated = [...widget.items, val];
    _addCtrl.clear();
    widget.onChanged(updated);
  }

  void _remove(int index) {
    final updated = List<String>.from(widget.items)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.emptyMessage,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (_editingIndex == index) {
                // ── Edit row ──
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _editCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _confirmEdit(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Confirmar',
                      onPressed: _confirmEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Cancelar',
                      onPressed: _cancelEdit,
                    ),
                  ],
                );
              }
              // ── Read-only row ──
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.items[index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Editar',
                    onPressed: () => _startEdit(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outlined, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Eliminar',
                    onPressed: () => _remove(index),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                decoration: InputDecoration(
                  hintText: widget.addHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _add,
              icon: const Icon(Icons.add),
              tooltip: widget.addLabel ?? 'Agregar',
              style: IconButton.styleFrom(
                backgroundColor: null,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
