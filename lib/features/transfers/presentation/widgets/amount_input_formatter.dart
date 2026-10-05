import 'package:flutter/services.dart';

/// Solo dígitos y un separador decimal (`.` o `,`) con hasta 2 decimales.
class AmountInputFormatter extends TextInputFormatter {
  static final _valid = RegExp(r'^\d{0,13}([.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _valid.hasMatch(newValue.text) ? newValue : oldValue;
}
