import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/features/auth/application/logout.dart';
import 'package:nexo_bank/features/auth/application/restore_session.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';

class _MockRestore extends Mock implements RestoreSession {}

class _MockLogout extends Mock implements Logout {}

void main() {
  late _MockRestore restore;
  late _MockLogout logout;
  late int clears;
  const session = Session(customerId: 'c-1');

  setUp(() {
    restore = _MockRestore();
    logout = _MockLogout();
    clears = 0;
    when(() => logout()).thenAnswer((_) async {});
  });

  SessionCubit build() => SessionCubit(
    restoreSession: restore,
    logout: logout,
    clearUserData: () async => clears++,
  );

  blocTest<SessionCubit, SessionState>(
    'restore con sesión guardada → autenticado',
    setUp: () => when(() => restore()).thenAnswer((_) async => session),
    build: build,
    act: (c) => c.restore(),
    expect: () => const [SessionAuthenticated(session, restored: true)],
  );

  blocTest<SessionCubit, SessionState>(
    'restore sin sesión → no autenticado',
    setUp: () => when(() => restore()).thenAnswer((_) async => null),
    build: build,
    act: (c) => c.restore(),
    expect: () => const [SessionUnauthenticated()],
  );

  blocTest<SessionCubit, SessionState>(
    'logout borra tokens y caché y pasa a no autenticado',
    build: build,
    seed: () => const SessionAuthenticated(session),
    act: (c) => c.logout(),
    expect: () => const [SessionUnauthenticated()],
    verify: (_) {
      verify(() => logout()).called(1);
      expect(clears, 1);
    },
  );

  blocTest<SessionCubit, SessionState>(
    'sessionExpired solo aplica si había sesión',
    build: build,
    seed: () => const SessionAuthenticated(session),
    act: (c) => c
      ..sessionExpired()
      ..sessionExpired(),
    expect: () => const [SessionUnauthenticated(expired: true)],
    verify: (_) => expect(clears, 1),
  );
}
