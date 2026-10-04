import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Pantalla temporal para rutas cuya feature aún no se implementa.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyView(
        message: 'Próximamente',
        icon: Icons.construction_outlined,
      ),
    );
  }
}
