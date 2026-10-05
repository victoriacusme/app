import '../../../core/security/auth_tokens.dart';

/// Respuesta de `/auth/login`, `/auth/refresh` y `/auth/register`.
class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) =>
      TokenResponseDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
      );

  final String accessToken;
  final String refreshToken;

  /// Segundos de vida del access token.
  final int expiresIn;

  AuthTokens toTokens({DateTime? now}) => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: (now ?? DateTime.now()).toUtc().add(
      Duration(seconds: expiresIn),
    ),
  );
}
