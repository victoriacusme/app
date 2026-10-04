import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: NexoColors.primary,
      primary: NexoColors.primary,
      secondary: NexoColors.secondary,
      error: NexoColors.error,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: NexoColors.primary,
      brightness: Brightness.dark,
      primary: NexoColors.primaryDark,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    const fieldRadius = BorderRadius.all(Radii.md);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: const OutlineInputBorder(borderRadius: fieldRadius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTouchTarget + 4),
          shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radii.lg)),
      ),
    );
  }
}
