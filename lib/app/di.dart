import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/network/dio_client.dart';
import '../core/security/device_id_provider.dart';
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
import '../features/auth/application/restore_session.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/infrastructure/auth_remote_data_source.dart';
import '../features/auth/infrastructure/auth_repository_impl.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/transfers/application/get_own_accounts.dart';
import '../features/transfers/application/transfer_between_own_accounts.dart';
import '../features/transfers/domain/transfer_repository.dart';
import '../features/transfers/infrastructure/transfer_remote_data_source.dart';
import '../features/transfers/infrastructure/transfer_repository_impl.dart';
import '../features/transfers/presentation/bloc/own_transfer_bloc.dart';
import 'session_cubit.dart';

final getIt = GetIt.instance;

/// [cache] y [connectivity] se crean antes (en `main`) porque su
/// inicialización es asíncrona o depende de la plataforma.
void configureDependencies({
  required FlutterSecureStorage storage,
  required KeyValueCache cache,
  required ConnectivitySource connectivity,
}) {
  // Core
  getIt
    ..registerSingleton(storage)
    ..registerSingleton(cache)
    ..registerLazySingleton<TokenStore>(() => SecureTokenStore(getIt()))
    ..registerLazySingleton(() => DeviceIdProvider(getIt()))
    ..registerLazySingleton(() => ConnectivityCubit(connectivity))
    ..registerLazySingleton<Dio>(
      () => createDioClient(
        tokenStore: getIt(),
        // Se resuelven en diferido: AuthRemoteDataSource usa este mismo Dio.
        refresh: (refreshToken) async =>
            (await getIt<AuthRemoteDataSource>().refresh(refreshToken))
                .toTokens(),
        onSessionExpired: () => getIt<SessionCubit>().sessionExpired(),
      ),
    );

  // Auth
  getIt
    ..registerLazySingleton(() => AuthRemoteDataSource(getIt()))
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
    ..registerFactory(() => LoginBloc(getIt()));

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
    ..registerLazySingleton(() => TransferBetweenOwnAccounts(getIt(), getIt()))
    ..registerFactory(
      () => OwnTransferBloc(
        getOwnAccounts: getIt(),
        transfer: getIt(),
        newIdempotencyKey: const Uuid().v4,
      ),
    );

  // App
  getIt.registerLazySingleton(
    () => SessionCubit(
      restoreSession: getIt(),
      logout: getIt(),
      // Al cerrar o expirar la sesión no quedan datos del cliente.
      clearUserData: getIt<KeyValueCache>().clear,
    ),
  );
}
