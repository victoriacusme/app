import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/design_system/design_system.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/presentation/bloc/login_bloc.dart';
import 'package:nexo_bank/features/auth/presentation/pages/login_page.dart';

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class _MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

void main() {
  late _MockLoginBloc loginBloc;
  late _MockSessionCubit sessionCubit;

  setUpAll(() {
    registerFallbackValue(const LoginSubmitted(username: '', password: ''));
    registerFallbackValue(const Session(customerId: ''));
  });

  setUp(() {
    loginBloc = _MockLoginBloc();
    sessionCubit = _MockSessionCubit();
    when(() => loginBloc.state).thenReturn(const LoginState());
    when(() => sessionCubit.state).thenReturn(const SessionUnauthenticated());
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>.value(value: loginBloc),
          BlocProvider<SessionCubit>.value(value: sessionCubit),
        ],
        child: const LoginPage(),
      ),
    ),
  );

  testWidgets('con campos vacíos muestra errores y no envía', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Ingresa tu usuario'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    verifyNever(() => loginBloc.add(any()));
  });

  testWidgets('con datos válidos envía LoginSubmitted', (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const Key('login_username')), ' ana ');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'Nexo2026*',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    final event =
        verify(() => loginBloc.add(captureAny())).captured.single
            as LoginSubmitted;
    expect(event.username, ' ana ');
    expect(event.password, 'Nexo2026*');
  });

  testWidgets('la contraseña se oculta y se puede mostrar', (tester) async {
    await pump(tester);

    EditableText password() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login_password')),
        matching: find.byType(EditableText),
      ),
    );

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('mientras envía muestra el indicador y deshabilita el botón', (
    tester,
  ) async {
    when(() => loginBloc.state)
        .thenReturn(const LoginState(status: LoginStatus.submitting));
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('muestra el mensaje de error del estado', (tester) async {
    when(() => loginBloc.state).thenReturn(
      const LoginState(
        status: LoginStatus.failure,
        error: LoginError.invalidCredentials,
        message: 'Usuario o contraseña incorrectos.',
      ),
    );
    await pump(tester);

    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('al tener éxito avisa al SessionCubit', (tester) async {
    const session = Session(customerId: 'customer-1');
    whenListen(
      loginBloc,
      Stream.value(
        const LoginState(status: LoginStatus.success, session: session),
      ),
      initialState: const LoginState(),
    );
    await pump(tester);
    await tester.pump();

    verify(() => sessionCubit.authenticated(session)).called(1);
  });

  testWidgets('ofrece crear una cuenta', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('login_create_account')), findsOneWidget);
  });

  testWidgets('si la sesión expiró lo indica', (tester) async {
    when(() => sessionCubit.state)
        .thenReturn(const SessionUnauthenticated(expired: true));
    await pump(tester);

    expect(find.textContaining('sesión expiró'), findsOneWidget);
  });
}
