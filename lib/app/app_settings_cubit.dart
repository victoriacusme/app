import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/customer/domain/customer_profile.dart';
import '../features/customer/domain/customer_repository.dart';
import 'session_cubit.dart';

final class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  @override
  List<Object?> get props => [themeMode, notificationsEnabled];
}

/// Aplica en toda la app las preferencias del cliente (tema y avisos).
/// Al iniciar sesión carga el perfil (primero de la caché) y al cerrarla
/// vuelve a los valores por defecto.
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit({
    required SessionCubit session,
    required CustomerRepository customers,
  }) : _customers = customers,
       super(const AppSettings()) {
    _preferences = customers.preferences.listen(_apply);
    _session = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final CustomerRepository _customers;
  late final StreamSubscription<Preferences> _preferences;
  late final StreamSubscription<SessionState> _session;

  void _onSession(SessionState state) {
    switch (state) {
      case SessionAuthenticated():
        // Los errores se ignoran: el tema no bloquea el uso de la app.
        unawaited(_customers.watchProfile().drain<void>());
      case SessionUnauthenticated():
        emit(const AppSettings());
      case SessionUnknown():
        break;
    }
  }

  void _apply(Preferences p) => emit(
    AppSettings(
      themeMode: switch (p.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      notificationsEnabled: p.notificationsEnabled,
    ),
  );

  @override
  Future<void> close() async {
    await _preferences.cancel();
    await _session.cancel();
    return super.close();
  }
}
