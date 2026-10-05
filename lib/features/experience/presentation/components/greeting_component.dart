import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/time/app_clock.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../../customer/presentation/profile_bloc.dart';
import '../../domain/experience_layout.dart';

/// Saludo del home. Lo arma la app (no el backend): la franja horaria según
/// la hora local del teléfono y el nombre del perfil del cliente. Las props
/// del backend solo indican que el componente va en el layout.
class GreetingComponent extends StatelessWidget {
  const GreetingComponent({super.key});

  factory GreetingComponent.fromSpec(ComponentSpec spec) =>
      const GreetingComponent();

  /// Mismas franjas que usaba el backend: 5–12 mañana, 12–19 tarde.
  static String greeting(AppLocalizations l10n, DateTime now) =>
      switch (now.hour) {
        >= 5 && < 12 => l10n.greetingMorning,
        >= 12 && < 19 => l10n.greetingAfternoon,
        _ => l10n.greetingEvening,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final name = context.select((ProfileBloc b) => b.state.profile?.firstName);
    final hello = greeting(l10n, AppClock.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Semantics(
        header: true,
        child: Text(
          name == null || name.isEmpty
              ? hello
              : l10n.greetingWithName(hello, name),
          key: const Key('home_greeting'),
          style: theme.textTheme.headlineSmall,
        ),
      ),
    );
  }
}
