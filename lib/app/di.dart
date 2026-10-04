import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/security/device_id_provider.dart';
import '../core/security/token_store.dart';
import '../features/auth/application/login.dart';
import '../features/auth/application/logout.dart';
import '../features/auth/application/restore_session.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/infrastructure/auth_remote_data_source.dart';
import '../features/auth/infrastructure/auth_repository_impl.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import 'session_cubit.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Core
  getIt
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    )
    ..registerLazySingleton<TokenStore>(() => SecureTokenStore(getIt()))
    ..registerLazySingleton(() => DeviceIdProvider(getIt()))
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

  // App
  getIt.registerLazySingleton(
    () => SessionCubit(restoreSession: getIt(), logout: getIt()),
  );
}
