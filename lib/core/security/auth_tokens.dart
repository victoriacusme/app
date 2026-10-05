import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  @override
  List<Object?> get props => [accessToken, refreshToken, accessTokenExpiresAt];

  @override
  String toString() => 'AuthTokens(***)';
}
