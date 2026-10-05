import '../../../l10n/l10n.dart';

/// Texto de una prop del SDUI. Acepta un texto simple (`"Hola"`) o uno por
/// idioma (`{"es": "Hola", "en": "Hi"}`). Con un texto simple se muestra tal
/// cual: la traducción es responsabilidad del backend.
class LocalizedText {
  const LocalizedText._(this._text, this._byLanguage);

  /// Lanza [FormatException] si la prop no es un texto válido: el registry
  /// omite el componente.
  factory LocalizedText.parse(Object? value) => switch (value) {
    final String text => LocalizedText._(text, null),
    final Map<dynamic, dynamic> map
        when map.isNotEmpty && map.values.every((v) => v is String) =>
      LocalizedText._(null, map.cast<String, String>()),
    _ => throw FormatException('Texto SDUI inválido: $value'),
  };

  static LocalizedText? tryParse(Object? value) =>
      value == null ? null : LocalizedText.parse(value);

  final String? _text;
  final Map<String, String>? _byLanguage;

  /// `true` si el backend envió el texto por idioma.
  bool get isLocalized => _byLanguage != null;

  String resolve(String language) =>
      _text ??
      _byLanguage![language] ??
      _byLanguage![AppLanguages.fallback] ??
      _byLanguage!.values.first;
}
