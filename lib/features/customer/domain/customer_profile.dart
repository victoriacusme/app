import 'package:equatable/equatable.dart';

enum Segment { young, premium, entrepreneur, standard }

enum ThemePreference { light, dark, system }

class Preferences extends Equatable {
  const Preferences({
    this.language = 'es',
    this.theme = ThemePreference.system,
    this.notificationsEnabled = true,
    this.showPromotions = true,
  });

  final String language;
  final ThemePreference theme;
  final bool notificationsEnabled;
  final bool showPromotions;

  Preferences copyWith({
    String? language,
    ThemePreference? theme,
    bool? notificationsEnabled,
    bool? showPromotions,
  }) => Preferences(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    showPromotions: showPromotions ?? this.showPromotions,
  );

  @override
  List<Object?> get props => [
    language,
    theme,
    notificationsEnabled,
    showPromotions,
  ];
}

/// Perfil del cliente. Cédula y teléfono llegan enmascarados del backend.
class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.email,
    required this.maskedPhone,
    required this.maskedIdNumber,
    required this.segment,
    required this.preferences,
  });

  final String id;
  final String fullName;
  final String firstName;
  final String email;
  final String maskedPhone;
  final String maskedIdNumber;
  final Segment segment;
  final Preferences preferences;

  String get segmentLabel => switch (segment) {
    Segment.young => 'Joven',
    Segment.premium => 'Premium',
    Segment.entrepreneur => 'Emprendedor',
    Segment.standard => 'Personas',
  };

  CustomerProfile withPreferences(Preferences preferences) => CustomerProfile(
    id: id,
    fullName: fullName,
    firstName: firstName,
    email: email,
    maskedPhone: maskedPhone,
    maskedIdNumber: maskedIdNumber,
    segment: segment,
    preferences: preferences,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    firstName,
    email,
    maskedPhone,
    maskedIdNumber,
    segment,
    preferences,
  ];
}
