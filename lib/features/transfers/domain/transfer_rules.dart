import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';

/// Errores de validación del formulario de transferencia.
enum TransferError {
  sourceRequired,
  sourceInactive,
  targetRequired,
  targetSameAsSource,
  targetInactive,
  currencyMismatch,
  amountRequired,
  amountInvalid,
  amountNotPositive,
  insufficientBalance,
  descriptionTooLong,
}

/// Reglas que se validan en la app antes de enviar. El backend las vuelve
/// a validar: estas solo evitan viajes inútiles y dan mensajes inmediatos.
abstract final class TransferRules {
  static const maxDescriptionLength = 100;

  static TransferError? sourceError(Account? source) {
    if (source == null) return TransferError.sourceRequired;
    if (!source.isActive) return TransferError.sourceInactive;
    return null;
  }

  static TransferError? targetError(Account? source, Account? target) {
    if (target == null) return TransferError.targetRequired;
    if (source != null && target.id == source.id) {
      return TransferError.targetSameAsSource;
    }
    if (!target.isActive) return TransferError.targetInactive;
    if (source != null && source.currency != target.currency) {
      return TransferError.currencyMismatch;
    }
    return null;
  }

  static TransferError? amountError(Account? source, String text) {
    if (text.trim().isEmpty) return TransferError.amountRequired;
    final cents = Money.tryParseCents(text);
    if (cents == null) return TransferError.amountInvalid;
    if (cents <= 0) return TransferError.amountNotPositive;
    if (source != null && cents > source.balance.cents) {
      return TransferError.insufficientBalance;
    }
    return null;
  }

  static TransferError? descriptionError(String text) =>
      text.length > maxDescriptionLength
      ? TransferError.descriptionTooLong
      : null;
}
