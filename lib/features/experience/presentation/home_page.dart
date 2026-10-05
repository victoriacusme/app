import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_settings_cubit.dart';
import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/bloc/accounts_bloc.dart';
import '../../accounts/presentation/widgets/account_card.dart';
import '../../customer/presentation/profile_bloc.dart';
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
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectivityCubit, ConnectivityStatus>(
          // Al recuperar la red, todo el home se refresca solo.
          listenWhen: (prev, curr) =>
              prev == ConnectivityStatus.offline &&
              curr == ConnectivityStatus.online,
          listener: (context, _) => _refresh(context),
        ),
        BlocListener<AppSettingsCubit, AppSettings>(
          // Cambió algo que afecta al home (el idioma, al cambiar el del
          // teléfono, o las promociones): se pide otra vez el layout, que el
          // backend compone según las preferencias del cliente.
          // Solo entre preferencias del cliente con sesión: al cerrar sesión
          // vuelven los valores por defecto y no hay que recargar (los tokens
          // ya no existen y la llamada saldría sin autenticación).
          listenWhen: (prev, curr) =>
              prev.customerLoaded &&
              curr.customerLoaded &&
              (prev.language != curr.language ||
                  prev.showPromotions != curr.showPromotions),
          listener: (context, _) => context.read<ExperienceCubit>().load(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.appTitle),
          actions: [
            IconButton(
              key: const Key('home_profile'),
              tooltip: context.l10n.profileTitle,
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(Routes.profile),
            ),
          ],
        ),
        body: BlocBuilder<ExperienceCubit, ExperienceLayout?>(
          builder: (context, layout) {
            if (layout == null) return const _HomeSkeleton();
            // Si el cliente no quiere promociones se ocultan al instante,
            // sin esperar a que llegue el layout nuevo del backend.
            final showPromotions = context.select(
              (AppSettingsCubit c) => c.state.showPromotions,
            );
            final children = [
              for (final spec in layout.components)
                if (showPromotions || spec.type != 'promo_banner')
                  ?components.build(spec),
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
    required this.profile,
    required this.child,
    super.key,
  });

  final ExperienceCubit Function() experience;
  final AccountsBloc Function() accounts;
  final FxCubit Function() fx;

  /// Perfil del cliente: el saludo usa su nombre.
  final ProfileBloc Function() profile;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => experience()..load()),
      BlocProvider(create: (_) => accounts()..add(const AccountsRequested())),
      BlocProvider(create: (_) => fx()),
      BlocProvider(create: (_) => profile()..add(const ProfileRequested())),
    ],
    child: child,
  );
}
