/// Formatos de fecha en español sin depender de la inicialización de
/// `intl` (los nombres de mes están fijos).
abstract final class DateTexts {
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// "hace un momento", "hace 5 min", "hace 2 h", "hace 3 días".
  static String relative(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    final days = diff.inDays;
    return days == 1 ? 'hace 1 día' : 'hace $days días';
  }

  /// "Hoy", "Ayer" o "12 de octubre de 2026" (en hora local).
  static String dayHeader(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final today = _dateOnly((now ?? DateTime.now()).toLocal());
    final day = _dateOnly(local);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${local.day} de ${_months[local.month - 1]} de ${local.year}';
  }

  /// "14:05" en hora local.
  static String time(DateTime time) {
    final l = time.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// "4 de octubre de 2026, 14:05".
  static String dateTime(DateTime value) {
    final l = value.toLocal();
    return '${l.day} de ${_months[l.month - 1]} de ${l.year}, ${time(l)}';
  }

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
}
