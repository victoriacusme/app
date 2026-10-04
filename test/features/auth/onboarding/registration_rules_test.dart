import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/features/auth/domain/registration_rules.dart';

void main() {
  final today = DateTime(2026, 10, 4);

  test('mayoría de edad: cumple 18 hoy sí, mañana no', () {
    expect(
      RegistrationRules.birthDate(DateTime(2008, 10, 4), today: today),
      isNull,
    );
    expect(
      RegistrationRules.birthDate(DateTime(2008, 10, 5), today: today),
      'Debes ser mayor de edad',
    );
    expect(RegistrationRules.birthDate(null, today: today), isNotNull);
  });

  test('contraseña con las reglas de ms-auth', () {
    expect(RegistrationRules.password('corta1'), 'Mínimo 8 caracteres');
    expect(RegistrationRules.password('solotexto'), contains('número'));
    expect(RegistrationRules.password('12345678'), contains('letra'));
    expect(RegistrationRules.password('Clave2026x'), isNull);
  });

  test('usuario, cédula, correo y teléfono', () {
    expect(RegistrationRules.username('ab'), isNotNull);
    expect(RegistrationRules.username('ana.perez_1'), isNull);
    expect(RegistrationRules.username('ana perez'), isNotNull);
    expect(RegistrationRules.idNumber('0102030405'), isNull);
    expect(RegistrationRules.idNumber('010203040'), isNotNull);
    expect(RegistrationRules.email('ana@nexo.ec'), isNull);
    expect(RegistrationRules.email('ana@nexo'), isNotNull);
    expect(RegistrationRules.phone('+593 99 123 4567'), isNull);
    expect(RegistrationRules.phone('12345'), isNotNull);
    expect(RegistrationRules.fullName('Ana'), 'Ingresa nombre y apellido');
  });
}
