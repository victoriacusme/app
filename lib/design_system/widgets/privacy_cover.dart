import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tapa el contenido cuando la app deja de estar en primer plano, para que
/// el selector de apps no muestre saldos ni datos del cliente.
///
/// - iOS toma la captura del selector al pasar a `inactive`: se tapa ahí.
/// - En Android `inactive` también ocurre con diálogos del sistema (p. ej.
///   el permiso de notificaciones), y taparía la app detrás del diálogo;
///   se tapa al ocultarse y, en release, FLAG_SECURE protege el selector.
class PrivacyCover extends StatefulWidget {
  const PrivacyCover({
    required this.child,
    this.onBackgrounded,
    this.onForegrounded,
    super.key,
  });

  final Widget child;
  final VoidCallback? onBackgrounded;
  final VoidCallback? onForegrounded;

  @override
  State<PrivacyCover> createState() => _PrivacyCoverState();
}

class _PrivacyCoverState extends State<PrivacyCover> {
  late final AppLifecycleListener _listener;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () {
        if (defaultTargetPlatform == TargetPlatform.iOS) _cover(true);
      },
      onHide: () => _cover(true),
      onPause: widget.onBackgrounded,
      onResume: () {
        _cover(false);
        widget.onForegrounded?.call();
      },
    );
  }

  void _cover(bool value) {
    if (mounted && _covered != value) setState(() => _covered = value);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        if (_covered)
          Positioned.fill(
            child: ColoredBox(
              key: const Key('privacy_cover'),
              color: scheme.primary,
              child: Center(
                child: Icon(
                  Icons.account_balance,
                  size: 72,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
