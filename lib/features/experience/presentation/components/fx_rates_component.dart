import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/design_system.dart';
import '../../../fx/presentation/fx_cubit.dart';
import '../../domain/experience_layout.dart';

/// Tipo de cambio desde un servicio externo. Si falla y no hay datos
/// guardados, la sección **se oculta** sin afectar al resto del home.
class FxRatesComponent extends StatefulWidget {
  const FxRatesComponent({
    required this.title,
    required this.base,
    required this.symbols,
    super.key,
  });

  factory FxRatesComponent.fromSpec(ComponentSpec spec) => FxRatesComponent(
    title: spec.properties['title'] as String? ?? 'Tipo de cambio',
    base: spec.properties['base'] as String? ?? 'USD',
    symbols: (spec.properties['symbols'] as List<dynamic>).cast<String>(),
  );

  final String title;
  final String base;
  final List<String> symbols;

  @override
  State<FxRatesComponent> createState() => _FxRatesComponentState();
}

class _FxRatesComponentState extends State<FxRatesComponent> {
  static final _number = NumberFormat('#,##0.0000', 'es');

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
    final rates = state.rates;
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
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                      ),
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
                            _number.format(rate),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: Spacing.xs),
                Text(
                  state.stale
                      ? 'Referencial · no pudimos actualizar'
                      : 'Referencial · ${DateTexts.relative(rates.publishedAt)}',
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
