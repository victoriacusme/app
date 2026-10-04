import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/app_settings_cubit.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/customer/domain/customer_profile.dart';
import 'package:nexo_bank/features/customer/domain/customer_repository.dart';

class _MockSession extends MockCubit<SessionState> implements SessionCubit {}

class _MockCustomers extends Mock implements CustomerRepository {}

void main() {
  late _MockSession session;
  late _MockCustomers customers;
  late StreamController<Preferences> prefs;
  late StreamController<SessionState> sessionStates;

  setUp(() {
    session = _MockSession();
    customers = _MockCustomers();
    prefs = StreamController<Preferences>.broadcast();
    sessionStates = StreamController<SessionState>.broadcast();
    when(() => session.state).thenReturn(const SessionUnknown());
    when(() => session.stream).thenAnswer((_) => sessionStates.stream);
    when(() => customers.preferences).thenAnswer((_) => prefs.stream);
    when(customers.watchProfile).thenAnswer((_) => const Stream.empty());
  });

  blocTest<AppSettingsCubit, AppSettings>(
    'aplica el tema y los avisos de las preferencias del cliente',
    build: () => AppSettingsCubit(session: session, customers: customers),
    act: (_) => prefs.add(
      const Preferences(
        theme: ThemePreference.dark,
        notificationsEnabled: false,
      ),
    ),
    expect: () => const [
      AppSettings(themeMode: ThemeMode.dark, notificationsEnabled: false),
    ],
  );

  blocTest<AppSettingsCubit, AppSettings>(
    'al iniciar sesión carga el perfil; al cerrarla vuelve a los valores base',
    build: () => AppSettingsCubit(session: session, customers: customers),
    act: (_) async {
      sessionStates.add(const SessionAuthenticated(Session(customerId: 'c')));
      prefs.add(const Preferences(theme: ThemePreference.dark));
      await Future<void>.delayed(Duration.zero);
      sessionStates.add(const SessionUnauthenticated());
    },
    expect: () => const [AppSettings(themeMode: ThemeMode.dark), AppSettings()],
    verify: (_) => verify(customers.watchProfile).called(1),
  );
}
