import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/app_settings_cubit.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/core/result/result.dart';
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
  late String deviceLanguage;

  setUpAll(() => registerFallbackValue(const Preferences()));

  setUp(() {
    session = _MockSession();
    customers = _MockCustomers();
    prefs = StreamController<Preferences>.broadcast();
    sessionStates = StreamController<SessionState>.broadcast();
    deviceLanguage = 'es';
    when(() => session.state).thenReturn(const SessionUnknown());
    when(() => session.stream).thenAnswer((_) => sessionStates.stream);
    when(() => customers.preferences).thenAnswer((_) => prefs.stream);
    when(customers.watchProfile).thenAnswer((_) => const Stream.empty());
    when(() => customers.updatePreferences(any(), any()))
        .thenAnswer((i) async => Ok(i.positionalArguments[1] as Preferences));
  });

  AppSettingsCubit build() => AppSettingsCubit(
    session: session,
    customers: customers,
    deviceLanguage: () => deviceLanguage,
  );

  blocTest<AppSettingsCubit, AppSettings>(
    'aplica el tema, los avisos y las promociones del cliente',
    build: build,
    act: (_) => prefs.add(
      const Preferences(
        theme: ThemePreference.dark,
        notificationsEnabled: false,
        showPromotions: false,
      ),
    ),
    expect: () => const [
      AppSettings(
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
        showPromotions: false,
        language: 'es',
        customerLoaded: true,
      ),
    ],
  );

  blocTest<AppSettingsCubit, AppSettings>(
    'al iniciar sesión carga el perfil; al cerrarla vuelve a los valores base',
    build: build,
    act: (_) async {
      sessionStates.add(const SessionAuthenticated(Session(customerId: 'c')));
      prefs.add(const Preferences(theme: ThemePreference.dark));
      await Future<void>.delayed(Duration.zero);
      sessionStates.add(const SessionUnauthenticated());
    },
    expect: () => const [
      AppSettings(
        themeMode: ThemeMode.dark,
        language: 'es',
        customerLoaded: true,
      ),
      AppSettings(),
    ],
    verify: (_) => verify(customers.watchProfile).called(1),
  );

  test('el idioma es el del teléfono, no una preferencia de la app', () {
    deviceLanguage = 'en';
    final cubit = build();

    expect(cubit.languageCode, 'en');
  });

  test(
    'si el backend tiene otro idioma, se le informa el del teléfono',
    () async {
      deviceLanguage = 'en';
      build();

      prefs.add(const Preferences());
      await Future<void>.delayed(Duration.zero);

      final next =
          verify(() => customers.updatePreferences(any(), captureAny()))
                  .captured
                  .single
              as Preferences;
      expect(next.language, 'en');
    },
  );

  test('si coinciden no se llama al backend', () async {
    build();

    prefs.add(const Preferences());
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => customers.updatePreferences(any(), any()));
  });

  test('al cambiar el idioma del teléfono se informa al backend', () async {
    final cubit = build();
    prefs.add(const Preferences());
    await Future<void>.delayed(Duration.zero);

    deviceLanguage = 'en';
    cubit.deviceLanguageChanged();

    verify(() => customers.updatePreferences(any(), any())).called(1);
  });

  test('sin sesión no se informa nada al backend', () {
    deviceLanguage = 'en';
    build().deviceLanguageChanged();

    verifyNever(() => customers.updatePreferences(any(), any()));
  });
}
