import 'dart:async';

import 'package:flutter/material.dart';

import '../formatters.dart';
import '../tokens.dart';

/// Indica que los datos visibles son guardados: "Datos de hace X min" o,
/// si el refresco falló, "No pudimos actualizar". Los datos no se ocultan.
class StaleDataBanner extends StatefulWidget {
  const StaleDataBanner({
    required this.updatedAt,
    this.refreshFailed = false,
    this.onRetry,
    super.key,
  });

  final DateTime updatedAt;
  final bool refreshFailed;
  final VoidCallback? onRetry;

  @override
  State<StaleDataBanner> createState() => _StaleDataBannerState();
}

class _StaleDataBannerState extends State<StaleDataBanner> {
  // Refresca el texto relativo ("hace X min") cada minuto.
  late final Timer _timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final age = DateTexts.relative(widget.updatedAt);
    final text = widget.refreshFailed
        ? 'No pudimos actualizar. Mostrando datos de $age.'
        : 'Datos de $age. Actualizando…';
    final fg = widget.refreshFailed
        ? scheme.onTertiaryContainer
        : scheme.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: widget.refreshFailed
            ? scheme.tertiaryContainer
            : scheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                widget.refreshFailed ? Icons.cloud_off_outlined : Icons.history,
                size: 20,
                color: fg,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Text(text, style: TextStyle(color: fg)),
                ),
              ),
              if (widget.refreshFailed && widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text('Reintentar', style: TextStyle(color: fg)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
