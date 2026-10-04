import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';

/// Reglas que se validan en la app antes de enviar. El backend las vuelve
/// a validar: estas solo evitan viajes inútiles y dan mensajes inmediatos.
abstract final class TransferRules {
  static const maxDescriptionLength = 100;

  static String? sourceError(Account? source) {
    if (source == null) return 'Elige la cuenta de origen';
    if (!source.isActive) return 'La cuenta de origen no está activa';
    return null;
  }

  static String? targetError(Account? source, Account? target) {
    if (target == null) return 'Elige la cuenta de destino';
    if (source != null && target.id == source.id) {
      return 'El destino debe ser otra cuenta';
    }
    if (!target.isActive) return 'La cuenta de destino no está activa';
    if (source != null && source.currency != target.currency) {
      return 'Las cuentas tienen monedas distintas';
    }
    return null;
  }

  static String? amountError(Account? source, String text) {
    if (text.trim().isEmpty) return 'Ingresa el monto';
    final cents = Money.tryParseCents(text);
    if (cents == null) return 'Ingresa un monto válido, por ejemplo 25.50';
    if (cents <= 0) return 'El monto debe ser mayor a cero';
    if (source != null && cents > source.balance.cents) {
      return 'Saldo insuficiente. Disponible: ${source.balance.format()}';
    }
    return null;
  }

  static String? descriptionError(String text) =>
      text.length > maxDescriptionLength
      ? 'Máximo $maxDescriptionLength caracteres'
      : null;
}
