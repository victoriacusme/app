import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import 'customer_profile.dart';

abstract interface class CustomerRepository {
  /// Perfil con stale-while-revalidate (caché y luego remoto).
  Stream<Result<Snapshot<CustomerProfile>>> watchProfile();

  /// Envía solo los campos cambiados (PATCH) y devuelve las preferencias
  /// que quedaron guardadas en el backend.
  Future<Result<Preferences>> updatePreferences(
    Preferences current,
    Preferences next,
  );

  /// Emite cada vez que se conocen preferencias nuevas (al cargar el perfil
  /// o al guardarlas), para aplicar el tema en toda la app.
  Stream<Preferences> get preferences;
}
