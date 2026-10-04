import 'package:flutter/material.dart';

import '../tokens.dart';

/// Estado de error con botón de reintento. Muestra el correlation-id
/// (si lo hay) para que soporte pueda rastrear la petición.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.onRetry,
    this.correlationId,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? correlationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (correlationId != null) ...[
              const SizedBox(height: Spacing.sm),
              SelectableText(
                'Código de soporte: $correlationId',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
