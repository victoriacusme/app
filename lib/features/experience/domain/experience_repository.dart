import 'experience_layout.dart';

abstract interface class ExperienceRepository {
  /// Emite el último layout guardado y luego el del backend. Nunca falla:
  /// sin caché ni backend, emite el layout de respaldo de la app.
  Stream<ExperienceLayout> watchHome();
}
