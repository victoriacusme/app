import 'package:equatable/equatable.dart';

/// Sesión activa del cliente. No expone los tokens a la UI.
class Session extends Equatable {
  const Session({required this.customerId});

  final String customerId;

  @override
  List<Object?> get props => [customerId];
}
