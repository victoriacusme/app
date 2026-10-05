import 'dart:async';

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
///
/// La franja se recalcula sola: al cambiar de franja con la app abierta y al
/// volver a la app (si quedó en segundo plano desde la mañana, de noche no
/// debe seguir diciendo "Buenos días").
class GreetingComponent extends StatefulWidget {
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

  /// Próximo cambio de franja (5:00, 12:00 o 19:00) después de [now].
  static DateTime nextChange(DateTime now) {
    for (final hour in const [5, 12, 19]) {
      final at = DateTime(now.year, now.month, now.day, hour);
      if (at.isAfter(now)) return at;
    }
    return DateTime(now.year, now.month, now.day + 1, 5);
  }

  @override
  State<GreetingComponent> createState() => _GreetingComponentState();
}

class _GreetingComponentState extends State<GreetingComponent> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _refresh,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _schedule();
  }

  /// Los timers se pausan con el teléfono dormido; por eso además se
  /// recalcula al volver a la app.
  void _schedule() {
    _timer?.cancel();
    final now = AppClock.now();
    _timer = Timer(GreetingComponent.nextChange(now).difference(now), _refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(_schedule);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final name = context.select((ProfileBloc b) => b.state.profile?.firstName);
    final hello = GreetingComponent.greeting(l10n, AppClock.now());
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
