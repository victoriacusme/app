import 'package:equatable/equatable.dart';

/// Un componente del SDUI: el `type` decide qué widget se dibuja y
/// [properties] (`props` en el JSON) lo configura.
class ComponentSpec extends Equatable {
  const ComponentSpec({
    required this.id,
    required this.type,
    this.properties = const {},
  });

  final String id;
  final String type;
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [id, type, properties];
}

/// Pantalla compuesta por el backend (`GET /experience/home`).
class ExperienceLayout extends Equatable {
  const ExperienceLayout({
    required this.screen,
    required this.segment,
    required this.components,
    this.isFallback = false,
  });

  final String screen;
  final String segment;
  final List<ComponentSpec> components;

  /// Layout incluido en la app: se usa si nunca se pudo obtener uno.
  final bool isFallback;

  @override
  List<Object?> get props => [screen, segment, components, isFallback];
}
