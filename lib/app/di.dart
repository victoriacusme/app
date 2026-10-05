import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/network/dio_client.dart';
import '../core/security/biometric_auth.dart';
import '../core/security/device_id_provider.dart';
import '../core/security/jwe_encryptor.dart';
import '../core/security/token_store.dart';
import '../core/storage/encrypted_cache.dart';
import '../features/accounts/application/get_movements.dart';
import '../features/accounts/application/watch_accounts.dart';
import '../features/accounts/domain/account_repository.dart';
import '../features/accounts/infrastructure/account_repository_impl.dart';
import '../features/accounts/infrastructure/accounts_local_data_source.dart';
import '../features/accounts/infrastructure/accounts_remote_data_source.dart';
import '../features/accounts/presentation/bloc/accounts_bloc.dart';
import '../features/accounts/presentation/bloc/movements_bloc.dart';
import '../features/auth/application/login.dart';
import '../features/auth/application/logout.dart';
import '../features/auth/application/register.dart';
import '../features/auth/application/restore_session.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/infrastructure/auth_remote_data_source.dart';
import '../features/auth/infrastructure/auth_repository_impl.dart';
import '../features/auth/infrastructure/jwks_client.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/onboarding/onboarding_cubit.dart';
import '../features/customer/application/update_preferences.dart';
import '../features/customer/application/watch_profile.dart';
import '../features/customer/domain/customer_repository.dart';
import '../features/customer/infrastructure/customer_remote_data_source.dart';
import '../features/customer/infrastructure/customer_repository_impl.dart';
import '../features/customer/presentation/profile_bloc.dart';
import '../features/experience/domain/experience_repository.dart';
import '../features/experience/infrastructure/experience_repository_impl.dart';
import '../features/experience/presentation/experience_cubit.dart';
import '../features/fx/domain/fx_repository.dart';
import '../features/fx/infrastructure/fx_repository_impl.dart';
import '../features/fx/presentation/fx_cubit.dart';
import '../features/notifications/application/local_transfer_notifier.dart';
import '../features/notifications/application/push_registration.dart';
import '../features/notifications/domain/push_token_source.dart';
import '../features/notifications/infrastructure/device_remote_data_source.dart';
import '../features/notifications/infrastructure/local_notifications_service.dart';
import '../features/transfers/application/get_own_accounts.dart';
import '../features/transfers/application/get_transfer_detail.dart';
import '../features/transfers/application/transfer_between_own_accounts.dart';
import '../features/transfers/domain/transfer_notifier.dart';
import '../features/transfers/domain/transfer_repository.dart';
import '../features/transfers/infrastructure/transfer_remote_data_source.dart';
import '../features/transfers/infrastructure/transfer_repository_impl.dart';
import '../features/transfers/presentation/bloc/own_transfer_bloc.dart';
import '../features/transfers/presentation/pages/transfer_detail_page.dart';
import '../l10n/l10n.dart';
import 'app_lock_cubit.dart';
import 'app_settings_cubit.dart';
import 'session_cubit.dart';

final getIt = GetIt.instance;

/// [cache] y [connectivity] se crean antes (en `main`) porque su
/// inicialización es asíncrona o depende de la plataforma.
void configureDependencies({
  required FlutterSecureStorage storage,
  required KeyValueCache cache,
  required ConnectivitySource connectivity,
  required LocalNotificationsService notifications,
}) {
  // Core
  getIt
    ..registerSingleton(storage)
    ..registerSingleton(cache)
    ..registerLazySingleton<TokenStore>(() => SecureTokenStore(getIt()))
    ..registerLazySingleton(() => DeviceIdProvider(getIt()))
    ..registerSingleton(notifications)
    ..registerLazySingleton(() => ConnectivityCubit(connectivity))
    ..registerLazySingleton<Dio>(
      () => createDioClient(
        tokenStore: getIt(),
        // Se resuelven en diferido: AuthRemoteDataSource usa este mismo Dio.
        refresh: (refreshToken) async =>
            (await getIt<AuthRemoteDataSource>().refresh(refreshToken))
                .toTokens(),
        onSessionExpired: () => getIt<SessionCubit>().sessionExpired(),
        language: () => getIt<AppSettingsCubit>().state.languageCode,
      ),
    );

  // Auth
  getIt
    ..registerLazySingleton(() => JwksClient(getIt()))
    ..registerLazySingleton(
      () => AuthRemoteDataSource(
        getIt(),
        // Login cifrado con JWE (Fase 8).
        jwks: getIt(),
        encryptor: JweEncryptor(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: getIt(),
        tokenStore: getIt(),
        deviceId: getIt(),
      ),
    )
    ..registerLazySingleton(() => Login(getIt()))
    ..registerLazySingleton(() => Logout(getIt()))
    ..registerLazySingleton(() => RestoreSession(getIt()))
    ..registerLazySingleton(() => Register(getIt()))
    ..registerFactory(() => LoginBloc(getIt()))
    ..registerFactory(() => OnboardingCubit(getIt()));

  // Accounts
  getIt
    ..registerLazySingleton(() => AccountsRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AccountsLocalDataSource(getIt()))
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(remote: getIt(), local: getIt()),
    )
    ..registerLazySingleton(() => WatchAccounts(getIt()))
    ..registerLazySingleton(() => GetMovements(getIt()))
    ..registerFactory(() => AccountsBloc(getIt()))
    ..registerFactoryParam<MovementsBloc, String, void>(
      (accountId, _) => MovementsBloc(getIt(), accountId: accountId),
    );

  // Transfers
  getIt
    ..registerLazySingleton(() => TransferRemoteDataSource(getIt()))
    ..registerLazySingleton<TransferRepository>(
      () => TransferRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetOwnAccounts(getIt()))
    ..registerLazySingleton(() => GetTransferDetail(getIt(), getIt()))
    ..registerFactoryParam<TransferDetailCubit, String, void>(
      (id, _) => TransferDetailCubit(getIt(), id),
    )
    ..registerLazySingleton(() => DeviceRemoteDataSource(getIt()))
    ..registerLazySingleton<PushTokenSource>(
      // Sin Firebase configurado no hay token (ver NoPushTokenSource).
      () => NoPushTokenSource(
        defaultTargetPlatform == TargetPlatform.iOS
            ? DevicePlatform.ios
            : DevicePlatform.android,
      ),
    )
    ..registerLazySingleton(() => PushRegistration(getIt(), getIt()))
    ..registerLazySingleton<TransferNotifier>(
      () => LocalTransferNotifier(
        service: getIt(),
        isEnabled: () => getIt<AppSettingsCubit>().state.notificationsEnabled,
        // El aviso se arma en el idioma activo de la app.
        l10n: () => lookupAppLocalizations(
          Locale(getIt<AppSettingsCubit>().state.languageCode),
        ),
      ),
    )
    ..registerLazySingleton(
      () => TransferBetweenOwnAccounts(getIt(), getIt(), getIt()),
    )
    ..registerFactory(
      () => OwnTransferBloc(
        getOwnAccounts: getIt(),
        transfer: getIt(),
        newIdempotencyKey: const Uuid().v4,
      ),
    );

  // Customer
  getIt
    ..registerLazySingleton(() => CustomerRemoteDataSource(getIt()))
    ..registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(remote: getIt(), cache: getIt()),
    )
    ..registerLazySingleton(() => WatchProfile(getIt()))
    ..registerLazySingleton(() => UpdatePreferences(getIt()))
    ..registerFactory(() => ProfileBloc(getIt(), getIt()));

  // Experience (SDUI) y tipo de cambio
  getIt
    ..registerLazySingleton<ExperienceRepository>(
      () => ExperienceRepositoryImpl(
        dio: getIt(),
        cache: getIt(),
        // Layout de respaldo en el idioma activo.
        loadFallback: () => rootBundle.loadString(
          'assets/experience/home_fallback_'
          '${getIt<AppSettingsCubit>().state.languageCode}.json',
        ),
      ),
    )
    ..registerFactory(() => ExperienceCubit(getIt()))
    ..registerLazySingleton<FxRepository>(
      () => FxRepositoryImpl(dio: getIt(), cache: getIt()),
    )
    ..registerFactory(() => FxCubit(getIt()));

  // App
  getIt
    ..registerLazySingleton(
      () => AppSettingsCubit(session: getIt(), customers: getIt()),
    )
    ..registerLazySingleton<BiometricAuth>(LocalBiometricAuth.new)
    ..registerLazySingleton(() => BiometricSettings(getIt()))
    ..registerLazySingleton(
      () => AppLockCubit(
        biometrics: getIt(),
        settings: getIt(),
        session: getIt(),
      ),
    );
  getIt.registerLazySingleton(
    () => SessionCubit(
      restoreSession: getIt(),
      logout: getIt(),
      // Al cerrar o expirar la sesión no quedan datos del cliente.
      clearUserData: getIt<KeyValueCache>().clear,
      onSignedIn: () => getIt<PushRegistration>().register(),
      onSigningOut: () => getIt<PushRegistration>().unregister(),
    ),
  );
}
