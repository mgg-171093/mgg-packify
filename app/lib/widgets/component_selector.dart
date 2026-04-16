import 'package:flutter/material.dart';
import '../core/theme/theme_extensions.dart';
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
    final surfaces =
        Theme.of(context).extension<SurfaceTokens>() ??
        SurfaceTokens.fromColorScheme(colorScheme);
    final effects = Theme.of(context).extension<PremiumEffects>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCanonicalComponentOrder.map((type) {
        final isSelected = selectedTypes.contains(type);
        return FilterChip(
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) => onToggle(type),
          selectedColor: surfaces.chipSelected,
          checkmarkColor: colorScheme.onPrimaryContainer,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.onPrimaryContainer : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          backgroundColor: surfaces.chipUnselected,
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          mouseCursor: effects?.actionCursor,
          showCheckmark: true,
        );
      }).toList(),
    );
  }
}
