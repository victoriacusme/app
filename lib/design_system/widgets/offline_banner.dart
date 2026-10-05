import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../tokens.dart';

/// Banner global que se muestra arriba de toda la app sin conexión.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.inverseSurface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 18, color: scheme.onInverseSurface),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.offlineBanner,
                    style: TextStyle(color: scheme.onInverseSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
