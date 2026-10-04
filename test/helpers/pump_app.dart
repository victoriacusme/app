import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/design_system/design_system.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit {}

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

/// Monta [child] con tema, router mínimo y los cubits globales.
Future<GoRouter> pumpPage(
  WidgetTester tester,
  Widget child, {
  ConnectivityCubit? connectivity,
  List<BlocProvider> providers = const [],
}) async {
  final conn = connectivity ?? MockConnectivityCubit();
  if (connectivity == null) {
    when(() => conn.state).thenReturn(ConnectivityStatus.online);
  }
  final session = MockSessionCubit();
  when(() => session.state).thenReturn(const SessionUnknown());
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, state) => Scaffold(body: Text('ruta:${state.uri}')),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>.value(value: conn),
        BlocProvider<SessionCubit>.value(value: session),
        ...providers,
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  return router;
}
