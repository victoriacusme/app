import '../domain/customer_profile.dart';

abstract final class CustomerDtos {
  static CustomerProfile profile(Map<String, dynamic> json) => CustomerProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    firstName: json['firstName'] as String,
    email: json['email'] as String,
    maskedPhone: json['phone'] as String,
    maskedIdNumber: json['idNumber'] as String,
    segment: switch (json['segment']) {
      'YOUNG' => Segment.young,
      'PREMIUM' => Segment.premium,
      'ENTREPRENEUR' => Segment.entrepreneur,
      _ => Segment.standard,
    },
    preferences: preferences(json['preferences'] as Map<String, dynamic>),
  );

  static Preferences preferences(Map<String, dynamic> json) => Preferences(
    language: json['language'] as String? ?? 'es',
    theme: switch (json['theme']) {
      'LIGHT' => ThemePreference.light,
      'DARK' => ThemePreference.dark,
      _ => ThemePreference.system,
    },
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    showPromotions: json['showPromotions'] as bool? ?? true,
  );

  static Map<String, dynamic> preferencesToJson(Preferences p) => {
    'language': p.language,
    'theme': p.theme.name.toUpperCase(),
    'notificationsEnabled': p.notificationsEnabled,
    'showPromotions': p.showPromotions,
  };

  /// Solo los campos que cambiaron (PATCH parcial).
  static Map<String, dynamic> preferencesPatch(
    Preferences current,
    Preferences next,
  ) {
    final before = preferencesToJson(current);
    return {
      for (final e in preferencesToJson(next).entries)
        if (before[e.key] != e.value) e.key: e.value,
    };
  }
}
