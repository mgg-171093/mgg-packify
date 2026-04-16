import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class PremiumEffects extends ThemeExtension<PremiumEffects> {
  const PremiumEffects({
    required this.hoverDuration,
    required this.focusRingWidth,
    required this.actionCursor,
    required this.standardCurve,
  });

  final Duration hoverDuration;
  final double focusRingWidth;
  final MouseCursor actionCursor;
  final Curve standardCurve;

  @override
  PremiumEffects copyWith({
    Duration? hoverDuration,
    double? focusRingWidth,
    MouseCursor? actionCursor,
    Curve? standardCurve,
  }) {
    return PremiumEffects(
      hoverDuration: hoverDuration ?? this.hoverDuration,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      actionCursor: actionCursor ?? this.actionCursor,
      standardCurve: standardCurve ?? this.standardCurve,
    );
  }

  @override
  PremiumEffects lerp(
    covariant ThemeExtension<PremiumEffects>? other,
    double t,
  ) {
    if (other is! PremiumEffects) {
      return this;
    }

    return PremiumEffects(
      hoverDuration: Duration(
        microseconds:
            (lerpDouble(
                      hoverDuration.inMicroseconds.toDouble(),
                      other.hoverDuration.inMicroseconds.toDouble(),
                      t,
                    ) ??
                    hoverDuration.inMicroseconds.toDouble())
                .round(),
      ),
      focusRingWidth:
          lerpDouble(focusRingWidth, other.focusRingWidth, t) ?? focusRingWidth,
      actionCursor: t < 0.5 ? actionCursor : other.actionCursor,
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
    );
  }
}

class SurfaceTokens extends ThemeExtension<SurfaceTokens> {
  const SurfaceTokens({
    required this.chipSelected,
    required this.chipUnselected,
    required this.cardElevated,
    required this.sidebarActive,
  });

  final Color chipSelected;
  final Color chipUnselected;
  final Color cardElevated;
  final Color sidebarActive;

  factory SurfaceTokens.fromColorScheme(ColorScheme colorScheme) {
    return SurfaceTokens(
      chipSelected: colorScheme.primaryContainer,
      chipUnselected: colorScheme.surfaceContainerLow,
      cardElevated: colorScheme.surfaceContainerHigh,
      sidebarActive: colorScheme.primaryContainer.withAlpha(128),
    );
  }

  @override
  SurfaceTokens copyWith({
    Color? chipSelected,
    Color? chipUnselected,
    Color? cardElevated,
    Color? sidebarActive,
  }) {
    return SurfaceTokens(
      chipSelected: chipSelected ?? this.chipSelected,
      chipUnselected: chipUnselected ?? this.chipUnselected,
      cardElevated: cardElevated ?? this.cardElevated,
      sidebarActive: sidebarActive ?? this.sidebarActive,
    );
  }

  @override
  SurfaceTokens lerp(covariant ThemeExtension<SurfaceTokens>? other, double t) {
    if (other is! SurfaceTokens) {
      return this;
    }

    return SurfaceTokens(
      chipSelected:
          Color.lerp(chipSelected, other.chipSelected, t) ?? chipSelected,
      chipUnselected:
          Color.lerp(chipUnselected, other.chipUnselected, t) ?? chipUnselected,
      cardElevated:
          Color.lerp(cardElevated, other.cardElevated, t) ?? cardElevated,
      sidebarActive:
          Color.lerp(sidebarActive, other.sidebarActive, t) ?? sidebarActive,
    );
  }
}
