import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/money/money.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/account.dart';
import '../bloc/accounts_bloc.dart';
import 'account_card.dart';

/// Sección de cuentas del home. Depende solo de `AccountsBloc`: si otros
/// servicios fallan (ms-customer, tipo de cambio), esta sección sigue
/// funcionando con sus propios datos y su caché.
class AccountsSection extends StatelessWidget {
  const AccountsSection({
    this.title = 'Tus cuentas',
    this.showTotal = false,
    super.key,
  });

  final String title;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsBloc>();
    final theme = Theme.of(context);
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (context, state) {
        final loading = state.status == AccountsStatus.loading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            if (showTotal && state.accounts.isNotEmpty)
              for (final total in _totals(state.accounts))
                Semantics(
                  label: 'Saldo total ${total.toSpeech()}',
                  excludeSemantics: true,
                  child: Text(
                    'Saldo total ${total.format()}',
                    key: const Key('accounts_total'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            const SizedBox(height: Spacing.md),
            if (state.status == AccountsStatus.failure)
              ErrorView(
                message: state.failure!.message,
                correlationId: state.failure!.correlationId,
                onRetry: () => bloc.add(const AccountsRequested()),
              )
            else if (loading)
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
          ],
        );
      },
    );
  }

  /// Total por moneda (no se suman monedas distintas).
  static Iterable<Money> _totals(List<Account> accounts) {
    final totals = <String, Money>{};
    for (final a in accounts.where((a) => a.isActive)) {
      totals[a.currency] =
          (totals[a.currency] ?? Money.zero(a.currency)) + a.balance;
    }
    return totals.values;
  }
}
