/// Validaciones del onboarding. Son las mismas que aplica ms-auth en
/// `RegisterRequest`, más la mayoría de edad.
abstract final class RegistrationRules {
  static const minAge = 18;

  static final _username = RegExp(r'^[A-Za-z0-9._]{3,30}$');
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp(r'\d');
  static final _idNumber = RegExp(r'^\d{10}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?\d{9,15}$');

  static String? fullName(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Ingresa tu nombre completo';
    if (!t.contains(' ')) return 'Ingresa nombre y apellido';
    if (t.length > 120) return 'Máximo 120 caracteres';
    return null;
  }

  static String? idNumber(String v) =>
      _idNumber.hasMatch(v.trim()) ? null : 'La cédula debe tener 10 dígitos';

  static String? birthDate(DateTime? v, {DateTime? today}) {
    if (v == null) return 'Elige tu fecha de nacimiento';
    final now = today ?? DateTime.now();
    if (!v.isBefore(now)) return 'La fecha debe ser anterior a hoy';
    var age = now.year - v.year;
    if (now.month < v.month || (now.month == v.month && now.day < v.day)) {
      age--;
    }
    return age < minAge ? 'Debes ser mayor de edad' : null;
  }

  static String? email(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Ingresa tu correo';
    if (t.length > 120 || !_email.hasMatch(t)) return 'Correo no válido';
    return null;
  }

  static String? phone(String v) => _phone.hasMatch(v.replaceAll(' ', ''))
      ? null
      : 'Teléfono no válido (9 a 15 dígitos)';

  static String? username(String v) => _username.hasMatch(v.trim())
      ? null
      : 'Entre 3 y 30 letras, números, "." o "_"';

  static String? password(String v) {
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (v.length > 128) return 'Máximo 128 caracteres';
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
      return 'Debe tener al menos una letra y un número';
    }
    return null;
  }

  static String? confirmation(String password, String confirmation) =>
      password == confirmation ? null : 'Las contraseñas no coinciden';
}
