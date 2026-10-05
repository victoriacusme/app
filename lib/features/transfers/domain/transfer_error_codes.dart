/// Valores de `code` en los `ProblemDetail` de `/transfers`.
abstract final class TransferErrorCodes {
  static const insufficientFunds = 'insufficient-funds';
  static const accountNotActive = 'account-not-active';
  static const sameAccount = 'same-account';
  static const invalidAmount = 'invalid-amount';
  static const currencyMismatch = 'currency-mismatch';
  static const accountNotOwned = 'account-not-owned';
  static const accountNotFound = 'account-not-found';
  static const idempotencyKeyReused = 'idempotency-key-reused';
}
