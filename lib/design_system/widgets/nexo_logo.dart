import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Logo de Nexo (el mismo del ícono de la app y del splash). Usa la versión
/// clara u oscura según el tema.
class NexoLogo extends StatelessWidget {
  const NexoLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark
          ? 'assets/branding/splash_logo_dark.png'
          : 'assets/branding/splash_logo.png',
      width: size,
      height: size,
      semanticLabel: context.l10n.appTitle,
    );
  }
}
