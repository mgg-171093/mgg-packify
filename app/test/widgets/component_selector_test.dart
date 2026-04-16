import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/theme/app_theme.dart';
import 'package:mgg_packify/core/theme/theme_extensions.dart';
import 'package:mgg_packify/models/component_config.dart';
import 'package:mgg_packify/widgets/component_selector.dart';

void main() {
  group('ComponentSelector', () {
    testWidgets('renders all 7 component types as chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComponentSelector(selectedTypes: const {}, onToggle: (_) {}),
          ),
        ),
      );

      for (final type in kCanonicalComponentOrder) {
        expect(find.text(type.label), findsOneWidget);
      }
    });

    testWidgets('calls onToggle with correct ComponentType on tap', (
      tester,
    ) async {
      ComponentType? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComponentSelector(
                selectedTypes: const {},
                onToggle: (type) => tapped = type,
              ),
            ),
          ),
        ),
      );

      // Tap the SQL chip
      await tester.tap(find.text('SQL'));
      await tester.pump();

      expect(tapped, ComponentType.sql);
    });

    testWidgets('selected chip shows different style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: ComponentSelector(
              selectedTypes: const {ComponentType.sql},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      // Find the SQL FilterChip — it should be selected
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'SQL'),
      );
      expect(chip.selected, isTrue);

      final context = tester.element(find.byType(ComponentSelector));
      final theme = Theme.of(context);
      final surfaces =
          theme.extension<SurfaceTokens>() ??
          SurfaceTokens.fromColorScheme(theme.colorScheme);

      expect(chip.selectedColor, equals(surfaces.chipSelected));
      expect(chip.checkmarkColor, equals(theme.colorScheme.onPrimaryContainer));
      expect(
        (chip.side as BorderSide).color,
        equals(theme.colorScheme.primary),
      );
    });

    testWidgets('unselected chip has selected=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: ComponentSelector(selectedTypes: const {}, onToggle: (_) {}),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'SQL'),
      );
      expect(chip.selected, isFalse);

      final context = tester.element(find.byType(ComponentSelector));
      final theme = Theme.of(context);
      final surfaces =
          theme.extension<SurfaceTokens>() ??
          SurfaceTokens.fromColorScheme(theme.colorScheme);

      expect(chip.backgroundColor, equals(surfaces.chipUnselected));
      expect(
        (chip.side as BorderSide).color,
        equals(theme.colorScheme.outlineVariant),
      );
    });

    testWidgets('chips appear in canonical order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComponentSelector(
                selectedTypes: const {},
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      );

      // Collect text positions
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      final labels = texts
          .map((t) => t.data ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // Check canonical order appears in the right sequence
      int lastIndex = -1;
      for (final type in kCanonicalComponentOrder) {
        final idx = labels.indexOf(type.label);
        expect(
          idx,
          greaterThan(lastIndex),
          reason: '${type.label} should appear after previous type',
        );
        lastIndex = idx;
      }
    });
  });
}
