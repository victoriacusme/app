import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/auth/application/register.dart';
import 'package:nexo_bank/features/auth/domain/registration.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/presentation/onboarding/onboarding_cubit.dart';

class _MockRegister extends Mock implements Register {}

void main() {
  late _MockRegister register;
  const session = Session(customerId: 'nuevo');

  setUpAll(
    () => registerFallbackValue(
      Registration(
        fullName: '',
        idNumber: '',
        birthDate: DateTime(2000),
        email: '',
        phone: '',
        username: '',
        password: '',
      ),
    ),
  );
  setUp(() => register = _MockRegister());

  /// Estado con todos los datos válidos, en el paso de términos.
  OnboardingState complete({OnboardingStep step = OnboardingStep.terms}) =>
      OnboardingState(
        step: step,
        values: const {
          OnboardingField.fullName: 'Ana Pérez',
          OnboardingField.idNumber: '0102030405',
          OnboardingField.email: 'ana@nexo.ec',
          OnboardingField.phone: '0991234567',
          OnboardingField.username: 'ana.perez',
          OnboardingField.password: 'Clave2026x',
          OnboardingField.confirmation: 'Clave2026x',
        },
        birthDate: DateTime(1995, 5, 10),
        acceptedTerms: true,
      );

  blocTest<OnboardingCubit, OnboardingState>(
    'no avanza con el paso incompleto y muestra los errores',
    build: () => OnboardingCubit(register),
    act: (c) => c.next(),
    expect: () => [
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.personal)
          .having((s) => s.showErrors, 'errors', true)
          .having(
            (s) => s.visibleError(OnboardingField.idNumber),
            'cédula',
            isNotNull,
          ),
    ],
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'avanza paso a paso y la barra de progreso crece',
    build: () => OnboardingCubit(register),
    seed: () => complete(step: OnboardingStep.personal),
    act: (c) async {
      await c.next();
      await c.next();
    },
    expect: () => [
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.credentials)
          .having((s) => s.progress, 'progress', 0.5),
      isA<OnboardingState>().having(
        (s) => s.step,
        'step',
        OnboardingStep.terms,
      ),
    ],
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'contraseñas distintas no permiten avanzar',
    build: () => OnboardingCubit(register),
    seed: () => complete(step: OnboardingStep.credentials),
    act: (c) {
      c.changed(OnboardingField.confirmation, 'Otra2026x');
      return c.next();
    },
    verify: (c) {
      expect(c.state.step, OnboardingStep.credentials);
      expect(
        c.state.visibleError(OnboardingField.confirmation),
        'Las contraseñas no coinciden',
      );
    },
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'éxito: envía el registro y pasa a bienvenida con la sesión',
    setUp: () =>
        when(() => register(any())).thenAnswer((_) async => const Ok(session)),
    build: () => OnboardingCubit(register),
    seed: complete,
    act: (c) => c.next(),
    verify: (c) {
      expect(c.state.step, OnboardingStep.welcome);
      expect(c.state.session, session);
      final sent =
          verify(() => register(captureAny())).captured.single as Registration;
      expect(sent.username, 'ana.perez');
    },
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'usuario tomado: vuelve a credenciales con el error en el campo',
    setUp: () => when(() => register(any())).thenAnswer(
      (_) async => const Err(
        ServerFailure(message: 'x', code: 'username-taken', statusCode: 409),
      ),
    ),
    build: () => OnboardingCubit(register),
    seed: complete,
    act: (c) => c.next(),
    verify: (c) {
      expect(c.state.step, OnboardingStep.credentials);
      expect(
        c.state.visibleError(OnboardingField.username),
        contains('ya existe'),
      );
    },
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'errores del backend por campo: vuelve al primer paso con error',
    setUp: () => when(() => register(any())).thenAnswer(
      (_) async => const Err(
        ValidationFailure(
          message: 'La solicitud tiene datos inválidos',
          code: 'validation-error',
          statusCode: 400,
          fieldErrors: {'phone': 'no es un teléfono válido'},
        ),
      ),
    ),
    build: () => OnboardingCubit(register),
    seed: complete,
    act: (c) => c.next(),
    verify: (c) {
      expect(c.state.step, OnboardingStep.personal);
      expect(
        c.state.visibleError(OnboardingField.phone),
        'no es un teléfono válido',
      );
    },
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'servicio no disponible: se queda en términos con un mensaje',
    setUp: () => when(() => register(any())).thenAnswer(
      (_) async => const Err(
        ServerFailure(code: 'onboarding-unavailable', statusCode: 503),
      ),
    ),
    build: () => OnboardingCubit(register),
    seed: complete,
    act: (c) => c.next(),
    verify: (c) {
      expect(c.state.step, OnboardingStep.terms);
      expect(c.state.failureMessage, contains('No pudimos completar'));
      expect(c.state.submitting, isFalse);
    },
  );

  test('back vuelve un paso y en el primero devuelve false', () {
    final cubit = OnboardingCubit(register)
      ..emit(complete(step: OnboardingStep.credentials));

    expect(cubit.back(), isTrue);
    expect(cubit.state.step, OnboardingStep.personal);
    expect(cubit.back(), isFalse);
  });
}
