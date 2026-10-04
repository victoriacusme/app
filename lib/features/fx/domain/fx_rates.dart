import 'package:equatable/equatable.dart';

/// Tipos de cambio de referencia. Son informativos: no se usan para
/// operar dinero, por eso se guardan como `double`.
class FxRates extends Equatable {
  const FxRates({
    required this.base,
    required this.rates,
    required this.publishedAt,
  });

  final String base;
  final Map<String, double> rates;

  /// Fecha de publicación del proveedor (no la de la consulta).
  final DateTime publishedAt;

  @override
  List<Object?> get props => [base, rates, publishedAt];
}
