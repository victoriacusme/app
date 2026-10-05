import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/app_lock_cubit.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/core/security/biometric_auth.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';

class _MockBiometrics extends Mock implements BiometricAuth {}

class _MockSettings extends Mock implements BiometricSettings {}

class _MockSession extends MockCubit<SessionState> implements SessionCubit {}

void main() {
  late _MockBiometrics biometrics;
  late _MockSettings settings;
  late _MockSession session;
  late StreamController<SessionState> sessions;
  late DateTime now;
  const s = Session(customerId: 'c');

  setUp(() {
    biometrics = _MockBiometrics();
    settings = _MockSettings();
    session = _MockSession();
    sessions = StreamController<SessionState>.broadcast();
    now = DateTime(2026);
    when(() => session.stream).thenAnswer((_) => sessions.stream);
    when(() => session.state).thenReturn(const SessionUnknown());
    when(biometrics.isAvailable).thenAnswer((_) async => true);
    when(settings.isEnabled).thenAnswer((_) async => true);
    when(() => settings.setEnabled(enabled: any(named: 'enabled')))
        .thenAnswer((_) async {});
  });

  AppLockCubit build() => AppLockCubit(
    biometrics: biometrics,
    settings: settings,
    session: session,
    now: () => now,
  );

  test('al restaurar la sesión con biometría activa, se bloquea', () async {
    final cubit = build();
    await cubit.init();

    sessions.add(const SessionAuthenticated(s, restored: true));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.locked, isTrue);
  });

  test('un login con contraseña no se bloquea', () async {
    final cubit = build();
    await cubit.init();

    sessions.add(const SessionAuthenticated(s));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.locked, isFalse);
  });

  test('sin biometría activada nunca se bloquea', () async {
    when(settings.isEnabled).thenAnswer((_) async => false);
    final cubit = build();
    await cubit.init();

    sessions.add(const SessionAuthenticated(s, restored: true));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.locked, isFalse);
  });

  test('vuelve a bloquear solo tras 1 minuto en segundo plano', () async {
    when(() => session.state).thenReturn(const SessionAuthenticated(s));
    final cubit = build();
    await cubit.init();

    cubit.onBackgrounded();
    now = now.add(const Duration(seconds: 30));
    cubit.onForegrounded();
    expect(cubit.state.locked, isFalse);

    cubit.onBackgrounded();
    now = now.add(const Duration(minutes: 2));
    cubit.onForegrounded();
    expect(cubit.state.locked, isTrue);
  });

  test('desbloquea solo si la biometría es correcta', () async {
    final cubit = build()
      ..emit(const AppLockState(available: true, enabled: true, locked: true));

    when(() => biometrics.authenticate(any())).thenAnswer((_) async => false);
    expect(await cubit.unlock(reason: 'r'), isFalse);
    expect(cubit.state.locked, isTrue);

    when(() => biometrics.authenticate(any())).thenAnswer((_) async => true);
    expect(await cubit.unlock(reason: 'r'), isTrue);
    expect(cubit.state.locked, isFalse);
  });

  test(
    'activar exige confirmar identidad; si se cancela no se activa',
    () async {
      when(settings.isEnabled).thenAnswer((_) async => false);
      when(() => biometrics.authenticate(any())).thenAnswer((_) async => false);
      final cubit = build();
      await cubit.init();

      expect(await cubit.setEnabled(enabled: true, reason: 'r'), isFalse);
      expect(cubit.state.enabled, isFalse);
      verifyNever(() => settings.setEnabled(enabled: true));
    },
  );

  test('al cerrar sesión se quita el bloqueo', () async {
    final cubit = build()
      ..emit(const AppLockState(available: true, enabled: true, locked: true));

    sessions.add(const SessionUnauthenticated());
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.locked, isFalse);
  });
}
