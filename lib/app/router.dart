import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/bloc/accounts_bloc.dart';
import '../features/accounts/presentation/bloc/movements_bloc.dart';
import '../features/accounts/presentation/pages/home_page.dart';
import '../features/accounts/presentation/pages/movements_page.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/transfers/presentation/bloc/own_transfer_bloc.dart';
import '../features/transfers/presentation/pages/transfer_page.dart';
import 'di.dart';
import 'pages/placeholder_page.dart';
import 'pages/splash_page.dart';
import 'routes.dart';
import 'session_cubit.dart';

export 'routes.dart';

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
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<AccountsBloc>()..add(const AccountsRequested()),
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    getIt<AccountsBloc>()..add(const AccountsRequested()),
              ),
              BlocProvider(
                create: (_) =>
                    getIt<MovementsBloc>(param1: id)
                      ..add(const MovementsRequested()),
              ),
            ],
            child: MovementsPage(accountId: id),
          );
        },
      ),
      GoRoute(
        path: Routes.transfer,
        builder: (_, state) => BlocProvider(
          create: (_) => getIt<OwnTransferBloc>()
            ..add(
              TransferStarted(
                sourceAccountId: state.uri.queryParameters['from'],
              ),
            ),
          child: const TransferPage(),
        ),
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
