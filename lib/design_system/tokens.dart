import 'package:flutter/material.dart';

/// Colores de marca. Los pares texto/fondo cumplen contraste WCAG AA.
abstract final class NexoColors {
  static const primary = Color(0xFF0B3D91);
  static const primaryDark = Color(0xFF8FB4FF);
  static const secondary = Color(0xFF00A88F);
  static const error = Color(0xFFB3261E);
  static const warning = Color(0xFF8A5300);
  static const success = Color(0xFF1B7F3B);
}

abstract final class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class Radii {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(20);
}

/// Área táctil mínima recomendada (accesibilidad).
const kMinTouchTarget = 48.0;
