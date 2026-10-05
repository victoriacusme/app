import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/app_lock_cubit.dart';
import 'package:nexo_bank/app/app_settings_cubit.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_dtos.dart';
import 'package:nexo_bank/features/customer/presentation/profile_bloc.dart';
import 'package:nexo_bank/design_system/design_system.dart';
import 'package:nexo_bank/l10n/l10n.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit {}

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class MockAppLockCubit extends MockCubit<AppLockState>
    implements AppLockCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettings>
    implements AppSettingsCubit {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

/// Perfil cargado con [firstName] (para el saludo del home).
MockProfileBloc profileOf(String firstName) {
  final bloc = MockProfileBloc();
  when(() => bloc.state).thenReturn(
    ProfileState(
      status: ProfileStatus.loaded,
      profile: CustomerDtos.profile({
        'id': 'c',
        'fullName': '$firstName Test',
        'firstName': firstName,
        'email': 'x@nexo.ec',
        'phone': '***1',
        'idNumber': '***1',
        'segment': 'YOUNG',
        'preferences': <String, dynamic>{},
      }),
    ),
  );
  return bloc;
}

/// MaterialApp con las traducciones de la app (español por defecto).
MaterialApp localizedApp({
  Widget? home,
  RouterConfig<Object>? routerConfig,
  Locale locale = const Locale('es'),
  ThemeData? theme,
}) {
  const delegates = AppLocalizations.localizationsDelegates;
  const locales = AppLocalizations.supportedLocales;
  final appTheme = theme ?? AppTheme.light();
  return routerConfig != null
      ? MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          locale: locale,
          localizationsDelegates: delegates,
          supportedLocales: locales,
          routerConfig: routerConfig,
        )
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          locale: locale,
          localizationsDelegates: delegates,
          supportedLocales: locales,
          home: home,
        );
}

/// Monta [child] con tema, router mínimo y los cubits globales.
Future<GoRouter> pumpPage(
  WidgetTester tester,
  Widget child, {
  ConnectivityCubit? connectivity,
  List<BlocProvider> providers = const [],
  Locale locale = const Locale('es'),
  AppSettingsCubit? settings,
}) async {
  final conn = connectivity ?? MockConnectivityCubit();
  if (connectivity == null) {
    when(() => conn.state).thenReturn(ConnectivityStatus.online);
  }
  final appSettings = settings ?? MockAppSettingsCubit();
  if (settings == null) {
    when(() => appSettings.state).thenReturn(const AppSettings());
  }
  final lock = MockAppLockCubit();
  when(() => lock.state).thenReturn(const AppLockState());
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
        BlocProvider<AppLockCubit>.value(value: lock),
        BlocProvider<AppSettingsCubit>.value(value: appSettings),
        ...providers,
      ],
      child: localizedApp(routerConfig: router, locale: locale),
    ),
  );
  return router;
}
