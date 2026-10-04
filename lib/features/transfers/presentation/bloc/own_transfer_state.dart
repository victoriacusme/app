part of 'own_transfer_bloc.dart';

enum TransferStep {
  loadingAccounts,
  accountsFailure,
  editing,
  confirming,
  submitting,
  success,
  rejected,

  /// No se sabe si se ejecutó (timeout, sin red, 5xx).
  unknown,
}

final class OwnTransferState extends Equatable {
  const OwnTransferState({
    this.step = TransferStep.loadingAccounts,
    this.accounts = const [],
    this.sourceId,
    this.targetId,
    this.amountText = '',
    this.description = '',
    this.showErrors = false,
    this.idempotencyKey,
    this.transfer,
    this.failure,
    this.failureMessage,
  });

  final TransferStep step;
  final List<Account> accounts;
  final String? sourceId;
  final String? targetId;
  final String amountText;
  final String description;

  /// Los errores se muestran tras el primer "Continuar".
  final bool showErrors;

  /// Se genera al pasar a confirmación: una por operación, no por petición.
  final String? idempotencyKey;
  final Transfer? transfer;
  final Failure? failure;
  final String? failureMessage;

  Account? get source => _find(sourceId);
  Account? get target => _find(targetId);

  /// Orígenes posibles: cuentas activas con saldo.
  List<Account> get sources =>
      accounts.where((a) => a.isActive && a.balance.isPositive).toList();

  /// Destinos posibles: cuentas activas, excepto el origen.
  List<Account> get targets =>
      accounts.where((a) => a.isActive && a.id != sourceId).toList();

  String? get sourceError => TransferRules.sourceError(source);
  String? get targetError => TransferRules.targetError(source, target);
  String? get amountError => TransferRules.amountError(source, amountText);
  String? get descriptionError => TransferRules.descriptionError(description);

  bool get isValid =>
      sourceError == null &&
      targetError == null &&
      amountError == null &&
      descriptionError == null;

  TransferDraft? get draft => isValid
      ? TransferDraft(
          source: source!,
          target: target!,
          amount: Money.parse(amountText, source!.currency),
          description: description.trim().isEmpty ? null : description.trim(),
        )
      : null;

  Account? _find(String? id) =>
      id == null ? null : accounts.where((a) => a.id == id).firstOrNull;

  OwnTransferState copyWith({
    TransferStep? step,
    List<Account>? accounts,
    String? Function()? sourceId,
    String? Function()? targetId,
    String? amountText,
    String? description,
    bool? showErrors,
    String? Function()? idempotencyKey,
    Transfer? Function()? transfer,
    Failure? Function()? failure,
    String? Function()? failureMessage,
  }) => OwnTransferState(
    step: step ?? this.step,
    accounts: accounts ?? this.accounts,
    sourceId: sourceId != null ? sourceId() : this.sourceId,
    targetId: targetId != null ? targetId() : this.targetId,
    amountText: amountText ?? this.amountText,
    description: description ?? this.description,
    showErrors: showErrors ?? this.showErrors,
    idempotencyKey: idempotencyKey != null
        ? idempotencyKey()
        : this.idempotencyKey,
    transfer: transfer != null ? transfer() : this.transfer,
    failure: failure != null ? failure() : this.failure,
    failureMessage: failureMessage != null
        ? failureMessage()
        : this.failureMessage,
  );

  @override
  List<Object?> get props => [
    step,
    accounts,
    sourceId,
    targetId,
    amountText,
    description,
    showErrors,
    idempotencyKey,
    transfer,
    failure,
    failureMessage,
  ];
}
