import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/domain/account.dart';
import '../bloc/own_transfer_bloc.dart';
import '../widgets/amount_input_formatter.dart';

/// Flujo completo de transferencia entre cuentas propias. Cada paso del
/// `OwnTransferBloc` se muestra como una vista: formulario, confirmación y
/// resultado (comprobante, rechazo o estado desconocido).
class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final step = context.select((OwnTransferBloc b) => b.state.step);
    final bloc = context.read<OwnTransferBloc>();
    return PopScope(
      // Mientras se envía no se puede salir; desde la confirmación, "atrás"
      // vuelve al formulario.
      canPop:
          step != TransferStep.submitting && step != TransferStep.confirming,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step == TransferStep.confirming) {
          bloc.add(const TransferEditRequested());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(step)),
          automaticallyImplyLeading: step != TransferStep.submitting,
        ),
        body: SafeArea(
          child: switch (step) {
            TransferStep.loadingAccounts => const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
            ),
            TransferStep.accountsFailure => ErrorView(
              message: bloc.state.failure!.message,
              correlationId: bloc.state.failure!.correlationId,
              onRetry: () => bloc.add(const TransferStarted()),
            ),
            TransferStep.editing => const TransferFormView(),
            TransferStep.confirming ||
            TransferStep.submitting => const TransferConfirmView(),
            TransferStep.success => const TransferReceiptView(),
            TransferStep.rejected => const _RejectedView(),
            TransferStep.unknown => const _UnknownView(),
          },
        ),
      ),
    );
  }

  static String _title(TransferStep step) => switch (step) {
    TransferStep.confirming || TransferStep.submitting => 'Confirmar',
    TransferStep.success => 'Comprobante',
    _ => 'Transferir',
  };
}

bool _isOffline(BuildContext context) =>
    context.watch<ConnectivityCubit>().state == ConnectivityStatus.offline;

/// Aviso fijo: sin conexión las transferencias no se encolan.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: Spacing.md),
    child: InlineMessage(
      key: Key('transfer_offline'),
      kind: InlineMessageKind.warning,
      message:
          'Sin conexión. Las transferencias necesitan internet: '
          'no se guardan para enviarse después.',
    ),
  );
}

class TransferFormView extends StatefulWidget {
  const TransferFormView({super.key});

  @override
  State<TransferFormView> createState() => _TransferFormViewState();
}

class _TransferFormViewState extends State<TransferFormView> {
  late final OwnTransferBloc _bloc = context.read<OwnTransferBloc>();
  late final _amount = TextEditingController(text: _bloc.state.amountText);
  late final _description = TextEditingController(
    text: _bloc.state.description,
  );

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = _isOffline(context);
    return BlocBuilder<OwnTransferBloc, OwnTransferState>(
      builder: (context, state) {
        if (state.sources.isEmpty || state.accounts.length < 2) {
          return const EmptyView(
            message:
                'Necesitas al menos dos cuentas activas, y una con '
                'saldo, para transferir entre tus cuentas.',
            icon: Icons.account_balance_wallet_outlined,
          );
        }
        String? error(String? message) => state.showErrors ? message : null;
        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            if (offline) const _OfflineNotice(),
            _AccountDropdown(
              key: const Key('transfer_source'),
              label: 'Desde',
              accounts: state.sources,
              selectedId: state.sourceId,
              errorText: error(state.sourceError),
              onChanged: (id) => _bloc.add(TransferSourceChanged(id)),
            ),
            const SizedBox(height: Spacing.md),
            _AccountDropdown(
              key: const Key('transfer_target'),
              label: 'Hacia',
              accounts: state.targets,
              selectedId: state.targets.any((a) => a.id == state.targetId)
                  ? state.targetId
                  : null,
              errorText: error(state.targetError),
              onChanged: (id) => _bloc.add(TransferTargetChanged(id)),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              key: const Key('transfer_amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AmountInputFormatter()],
              textInputAction: TextInputAction.next,
              onChanged: (v) => _bloc.add(TransferAmountChanged(v)),
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: r'$ ',
                helperText: state.source == null
                    ? null
                    : 'Disponible: ${state.source!.balance.format()}',
                errorText: error(state.amountError),
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              key: const Key('transfer_description'),
              controller: _description,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onChanged: (v) => _bloc.add(TransferDescriptionChanged(v)),
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                errorText: error(state.descriptionError),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            PrimaryButton(
              key: const Key('transfer_continue'),
              label: 'Continuar',
              onPressed: () {
                FocusScope.of(context).unfocus();
                _bloc.add(const TransferReviewRequested());
              },
            ),
          ],
        );
      },
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String label;
  final List<Account> accounts;
  final String? selectedId;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // La key cambia con las opciones para que el campo se reconstruya.
      key: ValueKey('$label-$selectedId-${accounts.length}'),
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Text(
              '${a.displayName} ${a.maskedNumber} · ${a.balance.format()}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
    );
  }
}

class TransferConfirmView extends StatelessWidget {
  const TransferConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OwnTransferBloc>().state;
    final bloc = context.read<OwnTransferBloc>();
    final draft = state.draft!;
    final submitting = state.step == TransferStep.submitting;
    final offline = _isOffline(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        if (offline) const _OfflineNotice(),
        Text(
          'Revisa los datos antes de confirmar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.md),
        _Summary(
          rows: [
            ('Monto', draft.amount.format()),
            (
              'Desde',
              '${draft.source.displayName} ${draft.source.maskedNumber}',
            ),
            (
              'Hacia',
              '${draft.target.displayName} ${draft.target.maskedNumber}',
            ),
            if (draft.description != null) ('Descripción', draft.description!),
            ('Saldo después', (draft.source.balance - draft.amount).format()),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        PrimaryButton(
          key: const Key('transfer_confirm'),
          label: 'Confirmar transferencia',
          loading: submitting,
          onPressed: offline ? null : () => bloc.add(const TransferConfirmed()),
        ),
        const SizedBox(height: Spacing.sm),
        TextButton(
          onPressed: submitting
              ? null
              : () => bloc.add(const TransferEditRequested()),
          child: const Text('Editar'),
        ),
      ],
    );
  }
}

class TransferReceiptView extends StatelessWidget {
  const TransferReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OwnTransferBloc>().state;
    final transfer = state.transfer!;
    final draft = state.draft!;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        const SizedBox(height: Spacing.md),
        const Icon(Icons.check_circle, size: 64, color: NexoColors.success),
        const SizedBox(height: Spacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(
            'Transferencia realizada',
            key: const Key('transfer_success'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _Summary(
          rows: [
            ('Monto', transfer.amount.format()),
            (
              'Desde',
              '${draft.source.displayName} ${draft.source.maskedNumber}',
            ),
            (
              'Hacia',
              '${draft.target.displayName} ${draft.target.maskedNumber}',
            ),
            if (transfer.description != null)
              ('Descripción', transfer.description!),
            ('Fecha', DateTexts.dateTime(transfer.createdAt)),
            ('Comprobante', transfer.id.split('-').first.toUpperCase()),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        PrimaryButton(
          key: const Key('transfer_done'),
          label: 'Volver al inicio',
          onPressed: () => context.go(Routes.home),
        ),
        const SizedBox(height: Spacing.sm),
        TextButton(
          onPressed: () =>
              context.read<OwnTransferBloc>().add(const TransferRestarted()),
          child: const Text('Hacer otra transferencia'),
        ),
      ],
    );
  }
}

class _RejectedView extends StatelessWidget {
  const _RejectedView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OwnTransferBloc>().state;
    return _ResultLayout(
      icon: Icons.cancel_outlined,
      color: Theme.of(context).colorScheme.error,
      title: 'No se realizó la transferencia',
      message: state.failureMessage ?? state.failure?.message ?? '',
      correlationId: state.failure?.correlationId,
      primaryLabel: 'Corregir datos',
      onPrimary: () =>
          context.read<OwnTransferBloc>().add(const TransferEditRequested()),
    );
  }
}

class _UnknownView extends StatelessWidget {
  const _UnknownView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OwnTransferBloc>().state;
    return _ResultLayout(
      icon: Icons.help_outline,
      color: NexoColors.warning,
      title: 'No pudimos confirmar el resultado',
      message:
          'La conexión se interrumpió y no sabemos si la transferencia '
          'se procesó. No la vuelvas a crear: toca "Verificar estado" y, si '
          'ya se hizo, verás el comprobante sin que se repita.',
      correlationId: state.failure?.correlationId,
      primaryLabel: 'Verificar estado',
      primaryKey: const Key('transfer_check_status'),
      onPrimary: _isOffline(context)
          ? null
          : () =>
                context.read<OwnTransferBloc>().add(const TransferConfirmed()),
    );
  }
}

class _ResultLayout extends StatelessWidget {
  const _ResultLayout({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.correlationId,
    this.primaryKey,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? correlationId;
  final String primaryLabel;
  final Key? primaryKey;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: Spacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(message, textAlign: TextAlign.center),
        if (correlationId != null) ...[
          const SizedBox(height: Spacing.sm),
          SelectableText(
            'Código de soporte: $correlationId',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: Spacing.lg),
        PrimaryButton(
          key: primaryKey,
          label: primaryLabel,
          onPressed: onPrimary,
        ),
        const SizedBox(height: Spacing.sm),
        TextButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Ir al inicio'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            for (final (label, value) in rows)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
