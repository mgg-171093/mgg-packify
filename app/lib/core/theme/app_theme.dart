import 'package:flutter/material.dart';

import 'theme_extensions.dart';

ThemeData appTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: brightness == Brightness.light
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surfaceContainerLow,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHigh,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    extensions: [
      const PremiumEffects(
        hoverDuration: Duration(milliseconds: 150),
        focusRingWidth: 2,
        actionCursor: SystemMouseCursors.click,
        standardCurve: Curves.easeInOut,
      ),
      SurfaceTokens.fromColorScheme(colorScheme),
    ],
  );
}
