import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design_system/design_system.dart';
import '../../l10n/l10n.dart';
import '../app_lock_cubit.dart';
import '../session_cubit.dart';

/// Pide la biometría para volver a entrar. Se puede salir con la
/// contraseña (cierra la sesión).
class LockedPage extends StatefulWidget {
  const LockedPage({super.key});

  @override
  State<LockedPage> createState() => _LockedPageState();
}

class _LockedPageState extends State<LockedPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Pide la biometría apenas se muestra la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    final ok = await context.read<AppLockCubit>().unlock(
      reason: context.l10n.biometricUnlockReason,
    );
    if (mounted && !ok) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.lockedTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _failed ? l10n.lockedFailed : l10n.lockedHint,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),
                PrimaryButton(
                  key: const Key('unlock_button'),
                  label: l10n.unlock,
                  onPressed: _unlock,
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: () => context.read<SessionCubit>().logout(),
                  child: Text(l10n.lockedUsePassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
