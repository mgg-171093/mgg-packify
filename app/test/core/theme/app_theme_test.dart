import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/core/theme/app_theme.dart';
import 'package:mgg_packify/core/theme/theme_extensions.dart';

void main() {
  group('appTheme', () {
    test('uses Deep Orange seeded color scheme for light theme', () {
      final theme = appTheme(Brightness.light);
      final expected = ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.light,
      );

      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, expected.primary);
      expect(theme.colorScheme.primaryContainer, expected.primaryContainer);
      expect(theme.colorScheme.onPrimary, expected.onPrimary);
    });

    test('uses Deep Orange seeded color scheme for dark theme', () {
      final theme = appTheme(Brightness.dark);
      final expected = ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.dark,
      );

      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, expected.primary);
      expect(theme.colorScheme.primaryContainer, expected.primaryContainer);
      expect(theme.colorScheme.onPrimary, expected.onPrimary);
    });

    test('registers PremiumEffects and SurfaceTokens extensions', () {
      final lightTheme = appTheme(Brightness.light);

      final premiumEffects = lightTheme.extension<PremiumEffects>();
      final surfaceTokens = lightTheme.extension<SurfaceTokens>();

      expect(premiumEffects, isNotNull);
      expect(surfaceTokens, isNotNull);
      expect(premiumEffects!.hoverDuration, const Duration(milliseconds: 150));
      expect(premiumEffects.focusRingWidth, 2);
      expect(premiumEffects.actionCursor, SystemMouseCursors.click);
      expect(premiumEffects.standardCurve, Curves.easeInOut);
      expect(
        surfaceTokens!.chipSelected,
        lightTheme.colorScheme.primaryContainer,
      );
      expect(
        surfaceTokens.chipUnselected,
        lightTheme.colorScheme.surfaceContainerLow,
      );
    });

    test('builds safe themes for both brightness values', () {
      expect(() => appTheme(Brightness.light), returnsNormally);
      expect(() => appTheme(Brightness.dark), returnsNormally);
    });
  });
}
