import '../../../core/network/error_mapper.dart';
import '../../../core/result/result.dart';
import '../../../core/security/device_id_provider.dart';
import '../../../core/security/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';
import 'auth_remote_data_source.dart';
import 'jwt_claims.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._tokenStore,
    required this._deviceId,
  });

  final AuthRemoteDataSource _remote;
  final TokenStore _tokenStore;
  final DeviceIdProvider _deviceId;

  @override
  Future<Result<Session>> login({
    required String username,
    required String password,
  }) async {
    try {
      final dto = await _remote.login(
        username: username,
        password: password,
        deviceId: await _deviceId.get(),
      );
      await _tokenStore.save(dto.toTokens());
      return Ok(Session(customerId: JwtClaims.subject(dto.accessToken)));
    } catch (e) {
      return Err(ErrorMapper.from(e));
    }
  }

  @override
  Future<void> logout() async {
    final tokens = await _tokenStore.read();
    await _tokenStore.clear();
    if (tokens == null) return;
    try {
      await _remote.logout(tokens.refreshToken);
    } catch (_) {
      // Best effort: localmente la sesión ya se cerró y el refresh token
      // expira solo en el backend.
    }
  }

  @override
  Future<Session?> currentSession() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) return null;
    try {
      return Session(customerId: JwtClaims.subject(tokens.accessToken));
    } on FormatException {
      await _tokenStore.clear();
      return null;
    }
  }
}
