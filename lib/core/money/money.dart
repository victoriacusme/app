import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Monto en unidades mínimas (centavos). Nunca usa `double`: la API envía
/// y recibe montos como texto decimal (`"1250.50"`).
class Money extends Equatable implements Comparable<Money> {
  const Money(this.cents, this.currency);

  const Money.zero(this.currency) : cents = 0;

  /// Acepta `"1250.50"`, `"1250.5"`, `"1250"` y `"-10.00"`. Si el usuario
  /// escribe coma decimal (`"25,50"`) también se acepta.
  factory Money.parse(String value, String currency) {
    final cents = tryParseCents(value);
    if (cents == null) throw FormatException('Monto inválido: $value');
    return Money(cents, currency);
  }

  static final _pattern = RegExp(r'^(-)?(\d{1,13})(?:[.,](\d{1,2}))?$');

  static int? tryParseCents(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;
    final units = int.parse(match.group(2)!);
    final decimals = int.parse((match.group(3) ?? '0').padRight(2, '0'));
    final cents = units * 100 + decimals;
    return match.group(1) == null ? cents : -cents;
  }

  final int cents;
  final String currency;

  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) => Money(cents + _same(other).cents, currency);
  Money operator -(Money other) => Money(cents - _same(other).cents, currency);
  Money operator -() => Money(-cents, currency);
  bool operator >(Money other) => cents > _same(other).cents;
  bool operator <(Money other) => cents < _same(other).cents;

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Monedas distintas: $currency y ${other.currency}');
    }
    return other;
  }

  /// Formato que espera la API: `"1250.50"`.
  String toApiString() {
    final abs = cents.abs();
    final sign = cents < 0 ? '-' : '';
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  static final _number = NumberFormat('#,##0.00', 'es');

  /// Formato para mostrar: `$1.250,50`, `-$10,00`, `+$10,00`.
  String format({bool signed = false}) {
    final text = '${_symbol(currency)}${_number.format(cents.abs() / 100)}';
    if (cents < 0) return '-$text';
    return signed && cents > 0 ? '+$text' : text;
  }

  /// Texto para lectores de pantalla: "1250 dólares con 50 centavos".
  String toSpeech() {
    final abs = cents.abs();
    final unit = currency == 'USD' ? 'dólares' : currency;
    final sign = cents < 0 ? 'menos ' : '';
    return '$sign${abs ~/ 100} $unit con ${abs % 100} centavos';
  }

  static String _symbol(String currency) => switch (currency) {
    'USD' => r'$',
    'EUR' => '€',
    _ => '$currency ',
  };

  @override
  int compareTo(Money other) => cents.compareTo(_same(other).cents);

  @override
  List<Object?> get props => [cents, currency];

  @override
  String toString() => '${toApiString()} $currency';
}
