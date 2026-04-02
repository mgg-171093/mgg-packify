import 'package:flutter/material.dart';
import '../models/component_config.dart';

class ComponentSelector extends StatelessWidget {
  const ComponentSelector({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
  });

  final Set<ComponentType> selectedTypes;
  final void Function(ComponentType) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCanonicalComponentOrder.map((type) {
        final isSelected = selectedTypes.contains(type);
        return FilterChip(
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) => onToggle(type),
          selectedColor: colorScheme.primary,
          checkmarkColor: colorScheme.onPrimary,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.onPrimary : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          backgroundColor: Colors.grey.shade100,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
          ),
          showCheckmark: true,
        );
      }).toList(),
    );
  }
}
