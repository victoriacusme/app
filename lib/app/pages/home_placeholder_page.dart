import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design_system/design_system.dart';
import '../session_cubit.dart';

/// Home temporal hasta la Fase 2 (cuentas). Permite validar login y logout.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionCubit>().state;
    final customerId = state is SessionAuthenticated
        ? state.session.customerId
        : '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexo Bank'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionCubit>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            'Sesión iniciada\n$customerId',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
