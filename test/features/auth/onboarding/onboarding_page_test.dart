import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/session_cubit.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/presentation/onboarding/onboarding_cubit.dart';
import 'package:nexo_bank/features/auth/presentation/onboarding/onboarding_page.dart';

import '../../../helpers/pump_app.dart';

class _MockOnboarding extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

class _MockSession extends MockCubit<SessionState> implements SessionCubit {}

void main() {
  late _MockOnboarding cubit;
  late _MockSession session;

  setUpAll(() => registerFallbackValue(const Session(customerId: '')));

  setUp(() {
    cubit = _MockOnboarding();
    session = _MockSession();
    when(() => session.state).thenReturn(const SessionUnauthenticated());
    when(() => cubit.next()).thenAnswer((_) async {});
    when(() => session.authenticated(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, OnboardingState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      localizedApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<OnboardingCubit>.value(value: cubit),
            BlocProvider<SessionCubit>.value(value: session),
          ],
          child: const OnboardingPage(),
        ),
      ),
    );
  }

  testWidgets('paso 1: muestra progreso y los errores de validación', (
    tester,
  ) async {
    await pump(tester, const OnboardingState(showErrors: true));

    expect(find.text('Tus datos'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('La cédula debe tener 10 dígitos'), findsOneWidget);
    expect(find.text('Elige tu fecha de nacimiento'), findsOneWidget);
  });

  testWidgets('escribir en un campo avisa al cubit y Continuar avanza', (
    tester,
  ) async {
    await pump(tester, const OnboardingState());

    await tester.enterText(
      find.byKey(const Key('onboarding_idNumber')),
      '0102030405',
    );
    await tester.tap(find.byKey(const Key('onboarding_next')));

    verify(() => cubit.changed(OnboardingField.idNumber, '0102030405'))
        .called(1);
    verify(() => cubit.next()).called(1);
  });

  testWidgets('la cédula solo acepta dígitos', (tester) async {
    await pump(tester, const OnboardingState());

    await tester.enterText(
      find.byKey(const Key('onboarding_idNumber')),
      '01ab02',
    );

    verify(() => cubit.changed(OnboardingField.idNumber, '0102')).called(1);
  });

  testWidgets('términos: el botón dice "Crear mi cuenta" y muestra carga', (
    tester,
  ) async {
    await pump(
      tester,
      const OnboardingState(step: OnboardingStep.terms, submitting: true),
    );

    expect(find.text('3/4'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('bienvenida: "Comenzar" inicia la sesión', (tester) async {
    const newSession = Session(customerId: 'nuevo');
    await pump(
      tester,
      const OnboardingState(
        step: OnboardingStep.welcome,
        values: {OnboardingField.fullName: 'Ana Pérez'},
        session: newSession,
      ),
    );

    expect(find.text('¡Listo, Ana!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_start')));

    verify(() => session.authenticated(newSession)).called(1);
  });

  testWidgets('al salir de un campo avisa al cubit para validarlo', (
    tester,
  ) async {
    await pump(tester, const OnboardingState());

    await tester.tap(find.byKey(const Key('onboarding_idNumber')));
    await tester.pump();
    // Pasar al siguiente campo quita el foco de la cédula.
    await tester.tap(find.byKey(const Key('onboarding_email')));
    await tester.pump();

    verify(() => cubit.fieldLeft(OnboardingField.idNumber)).called(1);
    verifyNever(() => cubit.fieldLeft(OnboardingField.email));
  });

  testWidgets('un campo visitado muestra su error antes de Continuar', (
    tester,
  ) async {
    await pump(
      tester,
      const OnboardingState(
        values: {OnboardingField.idNumber: '0102'},
        touched: {OnboardingField.idNumber},
      ),
    );

    expect(find.text('La cédula debe tener 10 dígitos'), findsOneWidget);
    // Los que no ha tocado todavía no muestran error.
    expect(find.text('Elige tu fecha de nacimiento'), findsNothing);
  });
}
