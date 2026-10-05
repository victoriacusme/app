import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/domain_l10n.dart';
import '../../../../l10n/l10n.dart';
import '../../application/get_transfer_detail.dart';
import '../../domain/transfer.dart';

/// `null` mientras carga.
class TransferDetailCubit extends Cubit<Result<TransferDetail>?> {
  TransferDetailCubit(this._get, this.id) : super(null);

  final GetTransferDetail _get;
  final String id;

  Future<void> load() async {
    emit(null);
    emit(await _get(id));
  }
}

/// Comprobante de una transferencia ya hecha (se abre desde el push
/// `app://transfers/{id}`).
class TransferDetailPage extends StatelessWidget {
  const TransferDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransferDetailCubit>().state;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptTitle)),
      body: switch (state) {
        null => Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.loading),
        ),
        Err(:final failure) => ErrorView(
          message: failure.localized(l10n),
          correlationId: failure.correlationId,
          onRetry: context.read<TransferDetailCubit>().load,
        ),
        Ok(value: final detail) => _Detail(detail: detail),
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final TransferDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = detail.transfer;
    final theme = Theme.of(context);
    String account(String id) =>
        detail.accounts.where((a) => a.id == id).firstOrNull?.label(l10n) ??
        l10n.ownAccount;
    final rows = [
      (l10n.amountLabel, t.amount.formatL(l10n)),
      (l10n.fromLabel, account(t.sourceAccountId)),
      (l10n.toLabel, account(t.targetAccountId)),
      if (t.description != null) (l10n.description, t.description!),
      (l10n.date, l10n.dateTime(t.createdAt)),
      (
        l10n.status,
        t.status == TransferStatus.completed
            ? l10n.statusCompleted
            : l10n.statusPending,
      ),
      (l10n.receiptNumber, t.id.split('-').first.toUpperCase()),
    ];
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        const Icon(Icons.receipt_long, size: 56, color: NexoColors.success),
        const SizedBox(height: Spacing.md),
        Card(
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
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: Text(value, textAlign: TextAlign.end),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
