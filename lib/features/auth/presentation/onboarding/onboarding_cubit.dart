import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/failure.dart';
import '../../../../core/result/result.dart';
import '../../application/register.dart';
import '../../domain/auth_error_codes.dart';
import '../../domain/registration.dart';
import '../../domain/registration_rules.dart';
import '../../domain/session.dart';

/// Pasos del onboarding, en orden.
enum OnboardingStep { personal, credentials, terms, welcome }

enum OnboardingField {
  fullName,
  idNumber,
  birthDate,
  email,
  phone,
  username,
  password,
  confirmation,
  terms,
}

final class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.personal,
    this.values = const {},
    this.birthDate,
    this.acceptedTerms = false,
    this.showErrors = false,
    this.submitting = false,
    this.serverErrors = const {},
    this.failure,
    this.session,
  });

  final OnboardingStep step;
  final Map<OnboardingField, String> values;
  final DateTime? birthDate;
  final bool acceptedTerms;

  /// Los errores del paso se muestran tras intentar avanzar.
  final bool showErrors;
  final bool submitting;

  /// Errores que devolvió el backend por campo (p. ej. usuario tomado).
  final Map<OnboardingField, RegistrationError> serverErrors;

  /// Error general del registro (sin campo asociado).
  final Failure? failure;
  final Session? session;

  String value(OnboardingField f) => values[f] ?? '';

  /// Progreso de 0 a 1 para la barra.
  double get progress => (step.index + 1) / OnboardingStep.values.length;

  static const fieldsByStep = {
    OnboardingStep.personal: [
      OnboardingField.fullName,
      OnboardingField.idNumber,
      OnboardingField.birthDate,
      OnboardingField.email,
      OnboardingField.phone,
    ],
    OnboardingStep.credentials: [
      OnboardingField.username,
      OnboardingField.password,
      OnboardingField.confirmation,
    ],
    OnboardingStep.terms: [OnboardingField.terms],
  };

  RegistrationError? errorOf(OnboardingField f) {
    final server = serverErrors[f];
    if (server != null) return server;
    return switch (f) {
      OnboardingField.fullName => RegistrationRules.fullName(value(f)),
      OnboardingField.idNumber => RegistrationRules.idNumber(value(f)),
      OnboardingField.birthDate => RegistrationRules.birthDate(birthDate),
      OnboardingField.email => RegistrationRules.email(value(f)),
      OnboardingField.phone => RegistrationRules.phone(value(f)),
      OnboardingField.username => RegistrationRules.username(value(f)),
      OnboardingField.password => RegistrationRules.password(value(f)),
      OnboardingField.confirmation => RegistrationRules.confirmation(
        value(OnboardingField.password),
        value(f),
      ),
      OnboardingField.terms =>
        acceptedTerms ? null : RegistrationError.termsRequired,
    };
  }

  /// Error visible en pantalla (solo después de intentar avanzar).
  RegistrationError? visibleError(OnboardingField f) =>
      showErrors || serverErrors.containsKey(f) ? errorOf(f) : null;

  bool isStepValid(OnboardingStep s) =>
      (fieldsByStep[s] ?? const []).every((f) => errorOf(f) == null);

  Registration toRegistration() => Registration(
    fullName: value(OnboardingField.fullName),
    idNumber: value(OnboardingField.idNumber),
    birthDate: birthDate!,
    email: value(OnboardingField.email),
    phone: value(OnboardingField.phone),
    username: value(OnboardingField.username),
    password: value(OnboardingField.password),
  );

  OnboardingState copyWith({
    OnboardingStep? step,
    Map<OnboardingField, String>? values,
    DateTime? birthDate,
    bool? acceptedTerms,
    bool? showErrors,
    bool? submitting,
    Map<OnboardingField, RegistrationError>? serverErrors,
    Failure? Function()? failure,
    Session? session,
  }) => OnboardingState(
    step: step ?? this.step,
    values: values ?? this.values,
    birthDate: birthDate ?? this.birthDate,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    showErrors: showErrors ?? this.showErrors,
    submitting: submitting ?? this.submitting,
    serverErrors: serverErrors ?? this.serverErrors,
    failure: failure != null ? failure() : this.failure,
    session: session ?? this.session,
  );

  @override
  List<Object?> get props => [
    step,
    values,
    birthDate,
    acceptedTerms,
    showErrors,
    submitting,
    serverErrors,
    failure,
    session,
  ];
}

/// Flujo: datos personales → credenciales → términos → bienvenida.
/// Cada paso se valida antes de avanzar; el registro se envía al aceptar
/// los términos.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._register) : super(const OnboardingState());

  final Register _register;

  static const _apiFields = {
    'fullName': OnboardingField.fullName,
    'idNumber': OnboardingField.idNumber,
    'birthDate': OnboardingField.birthDate,
    'email': OnboardingField.email,
    'phone': OnboardingField.phone,
    'username': OnboardingField.username,
    'password': OnboardingField.password,
  };

  void changed(OnboardingField field, String value) {
    final serverErrors = {...state.serverErrors}..remove(field);
    emit(
      state.copyWith(
        values: {...state.values, field: value},
        serverErrors: serverErrors,
      ),
    );
  }

  void birthDateChanged(DateTime date) {
    final serverErrors = {...state.serverErrors}
      ..remove(OnboardingField.birthDate);
    emit(state.copyWith(birthDate: date, serverErrors: serverErrors));
  }

  void termsChanged({required bool accepted}) =>
      emit(state.copyWith(acceptedTerms: accepted));

  /// "Continuar" en un paso.
  Future<void> next() async {
    if (state.submitting) return;
    if (!state.isStepValid(state.step)) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    switch (state.step) {
      case OnboardingStep.personal:
        emit(_goTo(OnboardingStep.credentials));
      case OnboardingStep.credentials:
        emit(_goTo(OnboardingStep.terms));
      case OnboardingStep.terms:
        await _submit();
      case OnboardingStep.welcome:
        break;
    }
  }

  /// "Atrás": vuelve al paso anterior. Devuelve `false` en el primero.
  bool back() {
    if (state.submitting) return true;
    return switch (state.step) {
      OnboardingStep.personal || OnboardingStep.welcome => false,
      OnboardingStep.credentials => _emitTrue(_goTo(OnboardingStep.personal)),
      OnboardingStep.terms => _emitTrue(_goTo(OnboardingStep.credentials)),
    };
  }

  bool _emitTrue(OnboardingState s) {
    emit(s);
    return true;
  }

  OnboardingState _goTo(OnboardingStep step) =>
      state.copyWith(step: step, showErrors: false, failure: () => null);

  Future<void> _submit() async {
    emit(state.copyWith(submitting: true, failure: () => null));
    final result = await _register(state.toRegistration());
    switch (result) {
      case Ok(value: final session):
        emit(
          state.copyWith(
            step: OnboardingStep.welcome,
            submitting: false,
            session: session,
          ),
        );
      case Err(:final failure):
        emit(_failureState(failure));
    }
  }

  OnboardingState _failureState(Failure failure) {
    final base = state.copyWith(submitting: false);
    if (failure.code == AuthErrorCodes.usernameTaken) {
      return base.copyWith(
        step: OnboardingStep.credentials,
        serverErrors: {
          OnboardingField.username: RegistrationError.usernameTaken,
        },
      );
    }
    if (failure case ValidationFailure(:final fieldErrors)
        when fieldErrors.isNotEmpty) {
      // El texto del backend no se muestra (viene en español): se marca
      // el campo y la app explica el error en el idioma activo.
      final errors = {
        for (final e in fieldErrors.entries)
          ?_apiFields[e.key]: RegistrationError.serverInvalid,
      };
      // Vuelve al primer paso que tenga un campo con error.
      final step = OnboardingStep.values.firstWhere(
        (s) => (OnboardingState.fieldsByStep[s] ?? const []).any(
          errors.containsKey,
        ),
        orElse: () => state.step,
      );
      return base.copyWith(
        step: step,
        serverErrors: errors,
        showErrors: true,
        failure: () => failure,
      );
    }
    return base.copyWith(failure: () => failure);
  }
}
