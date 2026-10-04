import 'package:flutter/material.dart';

import '../tokens.dart';

enum InlineMessageKind { error, warning, info }

/// Mensaje dentro del contenido (por ejemplo, error de un formulario).
/// Se anuncia al lector de pantalla como región viva.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    required this.message,
    this.kind = InlineMessageKind.error,
    super.key,
  });

  final String message;
  final InlineMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (kind) {
      InlineMessageKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      InlineMessageKind.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.lock_outline,
      ),
      InlineMessageKind.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radii.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}
