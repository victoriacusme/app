import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'di.dart';
import 'pages/home_placeholder_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/splash_page.dart';
import 'session_cubit.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const transfer = '/transfer';
  static const profile = '/profile';
  static String account(String id) => '/accounts/$id';
}

GoRouter createRouter(SessionCubit session) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) =>
        _redirect(session.state, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<LoginBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomePlaceholderPage(),
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (_, state) =>
            PlaceholderPage(title: 'Cuenta ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: Routes.transfer,
        builder: (_, _) => const PlaceholderPage(title: 'Transferir'),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, _) => const PlaceholderPage(title: 'Perfil'),
      ),
    ],
  );
}

String? _redirect(SessionState session, String location) {
  final isPublic = location == Routes.login || location == Routes.splash;
  return switch (session) {
    SessionUnknown() => location == Routes.splash ? null : Routes.splash,
    SessionUnauthenticated() => location == Routes.login ? null : Routes.login,
    SessionAuthenticated() => isPublic ? Routes.home : null,
  };
}

/// Notifica a go_router cada vez que cambia la sesión.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
