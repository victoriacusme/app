import '../features/accounts/domain/account.dart';
import '../features/auth/domain/registration_rules.dart';
import '../features/customer/domain/customer_profile.dart';
import '../features/transfers/domain/transfer_rules.dart';
import 'l10n.dart';

/// Textos de entidades del dominio en el idioma activo.
extension AccountL10n on Account {
  String typeLabel(AppLocalizations l10n) => switch (type) {
    AccountType.savings => l10n.accountTypeSavings,
    AccountType.checking => l10n.accountTypeChecking,
    AccountType.unknown => l10n.accountTypeGeneric,
  };

  /// Nombre para mostrar:
  /// - sin alias: el tipo de cuenta ("Cuenta de ahorros" / "Savings account");
  /// - alias genérico del banco ("Ahorros", "Corriente", "Cuenta de
  ///   ahorros"...): se traduce, validando que coincida con el tipo de la
  ///   cuenta (p. ej. "Ahorros" solo en una cuenta de ahorros);
  /// - alias propio del cliente ("Meta: viaje"): se respeta tal cual.
  String displayName(AppLocalizations l10n) {
    final alias = this.alias?.trim();
    if (alias == null || alias.isEmpty) return typeLabel(l10n);
    return switch ((_normalize(alias), type)) {
      ('cuenta de ahorros' || 'savings account', AccountType.savings) ||
      (
        'cuenta corriente' || 'checking account',
        AccountType.checking,
      ) => typeLabel(l10n),
      ('ahorros' || 'ahorro' || 'savings', AccountType.savings) =>
        l10n.aliasSavings,
      ('corriente' || 'checking', AccountType.checking) => l10n.aliasChecking,
      ('inversiones' || 'inversion' || 'investments', _) =>
        l10n.aliasInvestments,
      ('negocio' || 'business', _) => l10n.aliasBusiness,
      ('personal', _) => l10n.aliasPersonal,
      _ => alias,
    };
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  /// "Ahorros ****4521".
  String label(AppLocalizations l10n) => '${displayName(l10n)} $maskedNumber';
}

extension SegmentL10n on Segment {
  String label(AppLocalizations l10n) => switch (this) {
    Segment.young => l10n.segmentYoung,
    Segment.premium => l10n.segmentPremium,
    Segment.entrepreneur => l10n.segmentEntrepreneur,
    Segment.standard => l10n.segmentStandard,
  };
}

extension RegistrationErrorL10n on RegistrationError {
  String message(AppLocalizations l10n) => switch (this) {
    RegistrationError.fullNameRequired => l10n.regFullNameRequired,
    RegistrationError.fullNameSurname => l10n.regFullNameSurname,
    RegistrationError.fullNameTooLong => l10n.maxChars(
      RegistrationRules.maxNameLength,
    ),
    RegistrationError.idNumberInvalid => l10n.regIdNumber,
    RegistrationError.birthDateRequired => l10n.regBirthDateRequired,
    RegistrationError.birthDateFuture => l10n.regBirthDateFuture,
    RegistrationError.underage => l10n.regUnderage,
    RegistrationError.emailRequired => l10n.regEmailRequired,
    RegistrationError.emailInvalid => l10n.regEmailInvalid,
    RegistrationError.phoneInvalid => l10n.regPhoneInvalid,
    RegistrationError.usernameInvalid => l10n.regUsernameInvalid,
    RegistrationError.passwordTooShort => l10n.regPasswordTooShort(
      RegistrationRules.minPasswordLength,
    ),
    RegistrationError.passwordTooLong => l10n.maxChars(
      RegistrationRules.maxPasswordLength,
    ),
    RegistrationError.passwordWeak => l10n.regPasswordWeak,
    RegistrationError.passwordMismatch => l10n.regPasswordMismatch,
    RegistrationError.termsRequired => l10n.regTermsRequired,
    RegistrationError.usernameTaken => l10n.regUsernameTaken,
    RegistrationError.serverInvalid => l10n.regServerInvalid,
  };
}

extension TransferErrorL10n on TransferError {
  /// [source] se usa para mostrar el saldo disponible.
  String message(AppLocalizations l10n, {Account? source}) => switch (this) {
    TransferError.sourceRequired => l10n.transferSourceRequired,
    TransferError.sourceInactive => l10n.transferSourceInactive,
    TransferError.targetRequired => l10n.transferTargetRequired,
    TransferError.targetSameAsSource => l10n.transferTargetSame,
    TransferError.targetInactive => l10n.transferTargetInactive,
    TransferError.currencyMismatch => l10n.transferCurrencyMismatch,
    TransferError.amountRequired => l10n.transferAmountRequired,
    TransferError.amountInvalid => l10n.transferAmountInvalid,
    TransferError.amountNotPositive => l10n.transferAmountNotPositive,
    TransferError.insufficientBalance => l10n.transferInsufficient(
      source?.balance.formatL(l10n) ?? '',
    ),
    TransferError.descriptionTooLong => l10n.maxChars(
      TransferRules.maxDescriptionLength,
    ),
  };
}
