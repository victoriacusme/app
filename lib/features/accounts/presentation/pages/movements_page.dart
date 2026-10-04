import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/account.dart';
import '../../domain/movement.dart';
import '../bloc/accounts_bloc.dart';
import '../bloc/movements_bloc.dart';
import '../widgets/account_card.dart';
import '../widgets/movement_tile.dart';

/// Detalle de una cuenta con sus movimientos: scroll infinito,
/// pull-to-refresh y agrupación por día.
class MovementsPage extends StatefulWidget {
  const MovementsPage({required this.accountId, super.key});

  final String accountId;

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Pide la siguiente página un poco antes de llegar al final.
    if (_scroll.position.extentAfter < 400) {
      context.read<MovementsBloc>().add(const MovementsNextPageRequested());
    }
  }

  Future<void> _refresh() async {
    final movements = context.read<MovementsBloc>()
      ..add(const MovementsRequested());
    context.read<AccountsBloc>().add(const AccountsRequested());
    await movements.stream
        .firstWhere(
          (s) =>
              !s.fromCache ||
              s.refreshFailure != null ||
              s.status == MovementsStatus.failure,
          orElse: () => movements.state,
        )
        .timeout(const Duration(seconds: 30), onTimeout: () => movements.state);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.select(
      (AccountsBloc b) =>
          b.state.accounts.where((a) => a.id == widget.accountId).firstOrNull,
    );
    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      listenWhen: (prev, curr) =>
          prev == ConnectivityStatus.offline &&
          curr == ConnectivityStatus.online,
      listener: (_, _) => _refresh(),
      child: Scaffold(
        appBar: AppBar(title: Text(account?.displayName ?? 'Movimientos')),
        floatingActionButton: account != null && account.isActive
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.push(Routes.transferFrom(widget.accountId)),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Transferir'),
              )
            : null,
        body: BlocBuilder<MovementsBloc, MovementsState>(
          builder: (context, state) {
            if (state.status == MovementsStatus.failure) {
              return ErrorView(
                message: state.failure!.message,
                correlationId: state.failure!.correlationId,
                onRetry: () => context.read<MovementsBloc>().add(
                  const MovementsRequested(),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(Spacing.md),
                    sliver: SliverList.list(
                      children: [
                        if (account != null) AccountCard(account: account),
                        if (state.isStale && state.updatedAt != null) ...[
                          const SizedBox(height: Spacing.md),
                          StaleDataBanner(
                            updatedAt: state.updatedAt!,
                            refreshFailed: state.refreshFailure != null,
                            onRetry: _refresh,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ..._content(context, state, account),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    MovementsState state,
    Account? account,
  ) {
    if (state.status == MovementsStatus.loading) {
      return [
        SliverList.builder(
          itemCount: 6,
          itemBuilder: (_, _) => const _MovementSkeleton(),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            message: 'Esta cuenta aún no tiene movimientos.',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ];
    }
    final rows = _groupByDay(state.items);
    return [
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) => switch (rows[i]) {
          final String header => Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                header,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          final Movement movement => MovementTile(movement: movement),
          _ => const SizedBox.shrink(),
        },
      ),
      SliverToBoxAdapter(child: _Footer(state: state)),
    ];
  }

  /// Intercala encabezados de día ("Hoy", "Ayer", fecha) con movimientos.
  static List<Object> _groupByDay(List<Movement> items) {
    final rows = <Object>[];
    String? current;
    for (final m in items) {
      final header = DateTexts.dayHeader(m.bookedAt);
      if (header != current) {
        rows.add(header);
        current = header;
      }
      rows.add(m);
    }
    return rows;
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final MovementsState state;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (state.loadingMore) {
      child = const CircularProgressIndicator(semanticsLabel: 'Cargando más');
    } else if (state.loadMoreFailure != null) {
      child = TextButton.icon(
        onPressed: () => context.read<MovementsBloc>().add(
          const MovementsNextPageRequested(),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('No pudimos cargar más. Reintentar'),
      );
    } else if (!state.hasMore) {
      child = Text(
        'No hay más movimientos',
        style: Theme.of(context).textTheme.bodySmall,
      );
    } else {
      child = const SizedBox(height: kMinTouchTarget);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        96, // espacio para el botón flotante
      ),
      child: Center(child: child),
    );
  }
}

class _MovementSkeleton extends StatelessWidget {
  const _MovementSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
    child: Row(
      children: [
        Skeleton(width: 40, height: 40, radius: Radius.circular(20)),
        SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 160),
              SizedBox(height: Spacing.xs),
              Skeleton(width: 100, height: 12),
            ],
          ),
        ),
        Skeleton(width: 70),
      ],
    ),
  );
}
