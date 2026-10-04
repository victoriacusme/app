import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/security/biometric_auth.dart';
import 'session_cubit.dart';

final class AppLockState extends Equatable {
  const AppLockState({
    this.available = false,
    this.enabled = false,
    this.locked = false,
  });

  /// El dispositivo tiene biometría enrolada.
  final bool available;

  /// El cliente activó "Ingresar con biometría" en esta instalación.
  final bool enabled;

  /// La app está bloqueada esperando la biometría.
  final bool locked;

  AppLockState copyWith({bool? available, bool? enabled, bool? locked}) =>
      AppLockState(
        available: available ?? this.available,
        enabled: enabled ?? this.enabled,
        locked: locked ?? this.locked,
      );

  @override
  List<Object?> get props => [available, enabled, locked];
}

/// Bloqueo con biometría para volver a entrar sin escribir la contraseña:
///
/// - Al abrir la app con una sesión guardada.
/// - Al volver de segundo plano tras [relockAfter].
///
/// Un login con contraseña nunca queda bloqueado.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit({
    required this._biometrics,
    required this._settings,
    required this._session,
    this.relockAfter = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const AppLockState()) {
    _subscription = _session.stream.listen(_onSession);
  }

  final BiometricAuth _biometrics;
  final BiometricSettings _settings;
  final SessionCubit _session;
  final Duration relockAfter;
  final DateTime Function() _now;
  late final StreamSubscription<SessionState> _subscription;
  DateTime? _backgroundAt;

  /// Se llama antes de restaurar la sesión.
  Future<void> init() async {
    emit(
      state.copyWith(
        available: await _biometrics.isAvailable(),
        enabled: await _settings.isEnabled(),
      ),
    );
    _onSession(_session.state);
  }

  bool get _active => state.enabled && state.available;

  void _onSession(SessionState session) {
    switch (session) {
      case SessionAuthenticated(:final restored) when restored && _active:
        emit(state.copyWith(locked: true));
      case SessionUnauthenticated():
        emit(state.copyWith(locked: false));
      case _:
        break;
    }
  }

  void onBackgrounded() => _backgroundAt = _now();

  void onForegrounded() {
    final since = _backgroundAt;
    _backgroundAt = null;
    if (since == null || !_active) return;
    if (_session.state is SessionAuthenticated &&
        _now().difference(since) >= relockAfter) {
      emit(state.copyWith(locked: true));
    }
  }

  Future<bool> unlock() async {
    final ok = await _biometrics.authenticate('Desbloquea Nexo Bank');
    if (ok) emit(state.copyWith(locked: false));
    return ok;
  }

  /// Activar exige confirmar la identidad antes; desactivar no.
  Future<bool> setEnabled({required bool enabled}) async {
    if (enabled &&
        !await _biometrics.authenticate(
          'Confirma tu identidad para activarlo',
        )) {
      return false;
    }
    await _settings.setEnabled(enabled: enabled);
    emit(state.copyWith(enabled: enabled));
    return true;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
