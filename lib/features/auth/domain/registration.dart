import 'package:equatable/equatable.dart';

/// Datos para crear una cuenta (onboarding).
class Registration extends Equatable {
  const Registration({
    required this.fullName,
    required this.idNumber,
    required this.birthDate,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
  });

  final String fullName;
  final String idNumber;
  final DateTime birthDate;
  final String email;
  final String phone;
  final String username;
  final String password;

  @override
  List<Object?> get props => [
    fullName,
    idNumber,
    birthDate,
    email,
    phone,
    username,
  ];

  @override
  String toString() => 'Registration($username)';
}
