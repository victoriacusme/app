import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/session_cubit.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/accounts_bloc.dart';
import '../widgets/account_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      // Al recuperar la red, refresca solo.
      listenWhen: (prev, curr) =>
          prev == ConnectivityStatus.offline &&
          curr == ConnectivityStatus.online,
      listener: (context, _) =>
          context.read<AccountsBloc>().add(const AccountsRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nexo Bank'),
          actions: [
            IconButton(
              tooltip: 'Perfil',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(Routes.profile),
            ),
            IconButton(
              key: const Key('logout_button'),
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<SessionCubit>().logout(),
            ),
          ],
        ),
        body: const _AccountsBody(),
      ),
    );
  }
}

class _AccountsBody extends StatelessWidget {
  const _AccountsBody();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsBloc>();
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (context, state) {
        if (state.status == AccountsStatus.failure) {
          return ErrorView(
            message: state.failure!.message,
            correlationId: state.failure!.correlationId,
            onRetry: () => bloc.add(const AccountsRequested()),
          );
        }
        final loading = state.status == AccountsStatus.loading;
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const AccountsRequested());
            // Termina cuando llega el dato remoto o cuando falla.
            await bloc.stream
                .firstWhere(
                  (s) =>
                      !s.fromCache ||
                      s.refreshFailure != null ||
                      s.status == AccountsStatus.failure,
                )
                .timeout(const Duration(seconds: 30), onTimeout: () => state);
          },
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (state.isStale && state.updatedAt != null) ...[
                StaleDataBanner(
                  key: const Key('accounts_stale_banner'),
                  updatedAt: state.updatedAt!,
                  refreshFailed: state.refreshFailure != null,
                  onRetry: () => bloc.add(const AccountsRequested()),
                ),
                const SizedBox(height: Spacing.md),
              ],
              Semantics(
                header: true,
                child: Text(
                  'Tus cuentas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: Spacing.md),
              if (loading)
                for (var i = 0; i < 2; i++) ...[
                  const AccountCardSkeleton(),
                  const SizedBox(height: Spacing.md),
                ]
              else if (state.accounts.isEmpty)
                const EmptyView(
                  message: 'Todavía no tienes cuentas.',
                  icon: Icons.account_balance_wallet_outlined,
                )
              else
                for (final account in state.accounts) ...[
                  AccountCard(
                    account: account,
                    onTap: () => context.push(Routes.account(account.id)),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
              if (!loading && state.accounts.length > 1) ...[
                const SizedBox(height: Spacing.sm),
                FilledButton.tonalIcon(
                  key: const Key('home_transfer_button'),
                  onPressed: () => context.push(Routes.transfer),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Transferir entre mis cuentas'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
