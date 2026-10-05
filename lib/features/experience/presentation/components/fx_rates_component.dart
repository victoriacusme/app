import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/design_system.dart';
import '../../../fx/presentation/fx_cubit.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/experience_layout.dart';

/// Tipo de cambio desde un servicio externo. Si falla y no hay datos
/// guardados, la sección **se oculta** sin afectar al resto del home.
class FxRatesComponent extends StatefulWidget {
  const FxRatesComponent({
    required this.base,
    required this.symbols,
    super.key,
  });

  factory FxRatesComponent.fromSpec(ComponentSpec spec) => FxRatesComponent(
    base: spec.properties['base'] as String? ?? 'USD',
    symbols: (spec.properties['symbols'] as List<dynamic>).cast<String>(),
  );

  final String base;
  final List<String> symbols;

  @override
  State<FxRatesComponent> createState() => _FxRatesComponentState();
}

class _FxRatesComponentState extends State<FxRatesComponent> {
  @override
  void initState() {
    super.initState();
    context.read<FxCubit>().load(widget.base);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FxCubit>().state;
    if (state.hidden) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final number = NumberFormat('#,##0.0000', l10n.localeName);
    final rates = state.rates;
    // El título lo define la app, no el backend.
    final title = l10n.fxTitle;
    return Padding(
      key: const Key('fx_rates'),
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  Text('1 ${widget.base}', style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              if (rates == null)
                for (var i = 0; i < widget.symbols.length; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.xs),
                    child: Skeleton(height: 18),
                  )
              else ...[
                for (final symbol in widget.symbols)
                  if (rates.rates[symbol] case final rate?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                      child: Row(
                        children: [
                          Expanded(child: Text(symbol)),
                          Text(
                            number.format(rate),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: Spacing.xs),
                Text(
                  state.stale
                      ? l10n.fxStale
                      : l10n.fxReference(l10n.relative(rates.publishedAt)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
