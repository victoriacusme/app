/// Hora actual de la app. Se puede reemplazar en tests para fijar la hora.
abstract final class AppClock {
  static DateTime Function() now = DateTime.now;
}
