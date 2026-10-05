/// Errores de validación del onboarding. La pantalla los traduce.
enum RegistrationError {
  fullNameRequired,
  fullNameSurname,
  fullNameTooLong,
  idNumberInvalid,
  birthDateRequired,
  birthDateFuture,
  underage,
  emailRequired,
  emailInvalid,
  phoneInvalid,
  usernameInvalid,
  passwordTooShort,
  passwordTooLong,
  passwordWeak,
  passwordMismatch,
  termsRequired,

  /// El backend rechazó el usuario por existir.
  usernameTaken,

  /// El backend rechazó el dato (validación del servidor).
  serverInvalid,
}

/// Validaciones del onboarding. Son las mismas que aplica ms-auth en
/// `RegisterRequest`, más la mayoría de edad.
abstract final class RegistrationRules {
  static const minAge = 18;
  static const maxNameLength = 120;
  static const minPasswordLength = 8;
  static const maxPasswordLength = 128;

  static final _username = RegExp(r'^[A-Za-z0-9._]{3,30}$');
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp(r'\d');
  static final _idNumber = RegExp(r'^\d{10}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?\d{9,15}$');

  static RegistrationError? fullName(String v) {
    final t = v.trim();
    if (t.isEmpty) return RegistrationError.fullNameRequired;
    if (!t.contains(' ')) return RegistrationError.fullNameSurname;
    if (t.length > maxNameLength) return RegistrationError.fullNameTooLong;
    return null;
  }

  static RegistrationError? idNumber(String v) =>
      _idNumber.hasMatch(v.trim()) ? null : RegistrationError.idNumberInvalid;

  static RegistrationError? birthDate(DateTime? v, {DateTime? today}) {
    if (v == null) return RegistrationError.birthDateRequired;
    final now = today ?? DateTime.now();
    if (!v.isBefore(now)) return RegistrationError.birthDateFuture;
    var age = now.year - v.year;
    if (now.month < v.month || (now.month == v.month && now.day < v.day)) {
      age--;
    }
    return age < minAge ? RegistrationError.underage : null;
  }

  static RegistrationError? email(String v) {
    final t = v.trim();
    if (t.isEmpty) return RegistrationError.emailRequired;
    if (t.length > maxNameLength || !_email.hasMatch(t)) {
      return RegistrationError.emailInvalid;
    }
    return null;
  }

  static RegistrationError? phone(String v) =>
      _phone.hasMatch(v.replaceAll(' ', ''))
      ? null
      : RegistrationError.phoneInvalid;

  static RegistrationError? username(String v) =>
      _username.hasMatch(v.trim()) ? null : RegistrationError.usernameInvalid;

  static RegistrationError? password(String v) {
    if (v.length < minPasswordLength) return RegistrationError.passwordTooShort;
    if (v.length > maxPasswordLength) return RegistrationError.passwordTooLong;
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
      return RegistrationError.passwordWeak;
    }
    return null;
  }

  static RegistrationError? confirmation(
    String password,
    String confirmation,
  ) => password == confirmation ? null : RegistrationError.passwordMismatch;
}
