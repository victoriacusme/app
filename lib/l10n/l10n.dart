import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/money/money.dart';
import '../core/result/failure.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Idiomas de la app. El español es el idioma por defecto.
abstract final class AppLanguages {
  static const supported = ['es', 'en'];
  static const fallback = 'es';

  /// Normaliza un código de idioma ("en_US", "fr") a uno soportado.
  static String resolve(String? code) {
    final lang = code?.split(RegExp('[-_]')).first.toLowerCase();
    return supported.contains(lang) ? lang! : fallback;
  }

  /// Primer idioma soportado de la lista de preferencias del teléfono
  /// (p. ej. [fr, en] → en); si ninguno lo es, el de respaldo.
  static String resolveList(List<Locale>? locales) {
    for (final locale in locales ?? const <Locale>[]) {
      final lang = locale.languageCode.toLowerCase();
      if (supported.contains(lang)) return lang;
    }
    return fallback;
  }

  /// Idioma de la app: el del teléfono.
  static String device() =>
      resolveList(WidgetsBinding.instance.platformDispatcher.locales);
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension MoneyL10n on Money {
  /// `$1.250,50` en español, `$1,250.50` en inglés.
  String formatL(AppLocalizations l10n, {bool signed = false}) =>
      format(signed: signed, locale: l10n.localeName);

  /// Texto para lectores de pantalla.
  String speech(AppLocalizations l10n) {
    final abs = cents.abs();
    final text = currency == 'USD'
        ? l10n.moneySpeechUsd(abs ~/ 100, abs % 100)
        : l10n.moneySpeechOther(abs ~/ 100, abs % 100, currency);
    return cents < 0 ? l10n.moneySpeechNegative(text) : text;
  }
}

/// Fechas y tiempos relativos en el idioma activo.
extension DatesL10n on AppLocalizations {
  /// "hace 5 min" / "5 min ago".
  String relative(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return relativeNow;
    if (diff.inMinutes < 60) return relativeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return relativeHours(diff.inHours);
    return relativeDays(diff.inDays);
  }

  /// "Hoy", "Ayer" o "4 de octubre de 2026" / "October 4, 2026".
  String dayHeader(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final n = (now ?? DateTime.now()).toLocal();
    final days = DateTime(
      n.year,
      n.month,
      n.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;
    if (days == 0) return today;
    if (days == 1) return yesterday;
    return DateFormat.yMMMMd(localeName).format(local);
  }

  /// "14:05".
  String time(DateTime value) =>
      DateFormat.Hm(localeName).format(value.toLocal());

  /// "4 de octubre de 2026 14:05" / "October 4, 2026 14:05".
  String dateTime(DateTime value) =>
      DateFormat.yMMMMd(localeName).add_Hm().format(value.toLocal());

  /// Fecha corta: "10/5/1995" (es) / "5/10/1995" (en).
  String shortDate(DateTime value) => DateFormat.yMd(localeName).format(value);
}

/// Mensaje para el usuario a partir de un [Failure]. Se usa el `code`
/// estable del backend, nunca su `detail` (que llega en español).
extension FailureL10n on Failure {
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    TimeoutFailure() => l10n.errorTimeout,
    _ => switch (code) {
      'circuit-open' || 'service-unavailable' => l10n.errorServiceUnavailable,
      'rate-limited' => l10n.errorRateLimited,
      'invalid-credentials' => l10n.loginInvalidCredentials,
      'user-locked' => l10n.loginLocked,
      'onboarding-unavailable' => l10n.onboardingUnavailable,
      'transfer-not-found' => l10n.transferNotFound,
      'insufficient-funds' => l10n.rejectInsufficient(l10n.ownAccount),
      'account-not-active' => l10n.rejectAccountNotActive,
      'same-account' => l10n.rejectSameAccount,
      'currency-mismatch' => l10n.rejectCurrencyMismatch,
      'account-not-found' ||
      'account-not-owned' ||
      'customer-not-found' ||
      'not-found' => l10n.errorNotFound,
      _ => switch (this) {
        UnauthorizedFailure() => l10n.errorSession,
        ValidationFailure() => l10n.errorValidation,
        ServerFailure(statusCode: 503) => l10n.errorServiceUnavailable,
        ServerFailure(statusCode: 429) => l10n.errorRateLimited,
        ServerFailure(statusCode: 404) => l10n.errorNotFound,
        _ => l10n.errorUnexpected,
      },
    },
  };
}
