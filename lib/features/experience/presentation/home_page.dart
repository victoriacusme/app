import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../accounts/presentation/bloc/accounts_bloc.dart';
import '../../accounts/presentation/widgets/account_card.dart';
import '../../fx/presentation/fx_cubit.dart';
import '../domain/experience_layout.dart';
import 'component_registry.dart';
import 'experience_cubit.dart';

/// Home dinámico (SDUI): el backend decide qué secciones se ven y en qué
/// orden. Cada sección tiene su propio estado, así que si cae un servicio
/// solo se degrada su sección:
///
/// - ms-customer caído → se usa el último layout guardado o el de respaldo.
/// - ms-accounts caído → la sección de cuentas muestra su caché.
/// - Tipo de cambio caído → esa sección se oculta.
class HomePage extends StatelessWidget {
  const HomePage({this.registry, super.key});

  final ComponentRegistry? registry;

  Future<void> _refresh(BuildContext context) async {
    final accounts = context.read<AccountsBloc>()
      ..add(const AccountsRequested());
    await Future.wait([
      context.read<ExperienceCubit>().load(),
      accounts.stream
          .firstWhere(
            (s) =>
                !s.fromCache ||
                s.refreshFailure != null ||
                s.status == AccountsStatus.failure,
            orElse: () => accounts.state,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => accounts.state,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final components = registry ?? ComponentRegistry.defaults();
    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      // Al recuperar la red, todo el home se refresca solo.
      listenWhen: (prev, curr) =>
          prev == ConnectivityStatus.offline &&
          curr == ConnectivityStatus.online,
      listener: (context, _) => _refresh(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nexo Bank'),
          actions: [
            IconButton(
              key: const Key('home_profile'),
              tooltip: 'Mi perfil',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(Routes.profile),
            ),
          ],
        ),
        body: BlocBuilder<ExperienceCubit, ExperienceLayout?>(
          builder: (context, layout) {
            if (layout == null) return const _HomeSkeleton();
            final children = [
              for (final spec in layout.components) ?components.build(spec),
            ];
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                key: const Key('home_list'),
                padding: const EdgeInsets.all(Spacing.md),
                physics: const AlwaysScrollableScrollPhysics(),
                children: children,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Spacing.md),
    children: const [
      Skeleton(width: 220, height: 28),
      SizedBox(height: Spacing.lg),
      AccountCardSkeleton(),
      SizedBox(height: Spacing.md),
      AccountCardSkeleton(),
    ],
  );
}

/// Provee los estados de cada sección del home.
class HomeScope extends StatelessWidget {
  const HomeScope({
    required this.experience,
    required this.accounts,
    required this.fx,
    required this.child,
    super.key,
  });

  final ExperienceCubit Function() experience;
  final AccountsBloc Function() accounts;
  final FxCubit Function() fx;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => experience()..load()),
      BlocProvider(create: (_) => accounts()..add(const AccountsRequested())),
      BlocProvider(create: (_) => fx()),
    ],
    child: child,
  );
}
