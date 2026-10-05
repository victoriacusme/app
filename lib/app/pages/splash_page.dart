import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Pantalla de carga: el logo centrado sobre fondo liso, idéntica al splash
/// nativo para que la transición no se note mientras se recupera la sesión.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? NexoColors.splashDark : NexoColors.splashLight,
      body: const Center(child: NexoLogo()),
    );
  }
}
