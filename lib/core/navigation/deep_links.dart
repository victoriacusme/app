import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../l10n/l10n.dart';

/// Traduce los enlaces `app://...` del SDUI y de las notificaciones a rutas
/// de la app. Lo que no se reconoce devuelve `null`.
abstract final class DeepLinks {
  static String accountLink(String accountId) => 'app://accounts/$accountId';

  static String? routeFor(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'app') return null;
    // En app://accounts/123, "accounts" es el host y "/123" el path.
    final segments = [uri.host, ...uri.pathSegments.where((s) => s.isNotEmpty)];
    return switch (segments) {
      ['transfers' || 'transfer'] => Routes.transfer,
      // Push del backend tras una transferencia: app://transfers/{id}.
      ['transfers', final id] => Routes.transferDetail(id),
      ['accounts', final id] => Routes.account(id),
      ['profile'] => Routes.profile,
      ['home'] => Routes.home,
      _ => null,
    };
  }

  /// Navega o, si la función aún no existe en la app, avisa con un mensaje.
  static void open(BuildContext context, String link) {
    final route = routeFor(link);
    if (route != null) {
      context.push(route);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.comingSoon)));
  }
}
