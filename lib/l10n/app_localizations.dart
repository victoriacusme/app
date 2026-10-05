import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Nexo Bank'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get loading;

  /// No description provided for @loadingMore.
  ///
  /// In es, this message translates to:
  /// **'Cargando más'**
  String get loadingMore;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @supportCode.
  ///
  /// In es, this message translates to:
  /// **'Código de soporte: {code}'**
  String supportCode(String code);

  /// No description provided for @continueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Esta función estará disponible pronto.'**
  String get comingSoon;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @buttonLoading.
  ///
  /// In es, this message translates to:
  /// **'{label}, cargando'**
  String buttonLoading(String label);

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Verás los últimos datos guardados.'**
  String get offlineBanner;

  /// No description provided for @staleRefreshFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar. Mostrando datos de {age}.'**
  String staleRefreshFailed(String age);

  /// No description provided for @staleRefreshing.
  ///
  /// In es, this message translates to:
  /// **'Datos de {age}. Actualizando…'**
  String staleRefreshing(String age);

  /// No description provided for @relativeNow.
  ///
  /// In es, this message translates to:
  /// **'hace un momento'**
  String get relativeNow;

  /// No description provided for @relativeMinutes.
  ///
  /// In es, this message translates to:
  /// **'hace {count} min'**
  String relativeMinutes(int count);

  /// No description provided for @relativeHours.
  ///
  /// In es, this message translates to:
  /// **'hace {count} h'**
  String relativeHours(int count);

  /// No description provided for @relativeDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{hace 1 día} other{hace {count} días}}'**
  String relativeDays(int count);

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @moneySpeechUsd.
  ///
  /// In es, this message translates to:
  /// **'{units} dólares con {cents} centavos'**
  String moneySpeechUsd(int units, int cents);

  /// No description provided for @moneySpeechOther.
  ///
  /// In es, this message translates to:
  /// **'{units} {currency} con {cents} centavos'**
  String moneySpeechOther(int units, int cents, String currency);

  /// No description provided for @moneySpeechNegative.
  ///
  /// In es, this message translates to:
  /// **'menos {amount}'**
  String moneySpeechNegative(String amount);

  /// No description provided for @maxChars.
  ///
  /// In es, this message translates to:
  /// **'Máximo {max} caracteres'**
  String maxChars(int max);

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectarnos. Revisa tu conexión.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In es, this message translates to:
  /// **'El servidor tardó demasiado en responder.'**
  String get errorTimeout;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio no está disponible en este momento. Intenta nuevamente en unos segundos.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas solicitudes. Espera un momento e intenta nuevamente.'**
  String get errorRateLimited;

  /// No description provided for @errorSession.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión no es válida. Ingresa nuevamente.'**
  String get errorSession;

  /// No description provided for @errorValidation.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos ingresados.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos lo que buscabas.'**
  String get errorNotFound;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta nuevamente.'**
  String get errorUnexpected;

  /// No description provided for @loginWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Nexo'**
  String get loginWelcome;

  /// No description provided for @loginSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Ingresa nuevamente.'**
  String get loginSessionExpired;

  /// No description provided for @usernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginSubmit;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Usuario o contraseña incorrectos.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginLocked.
  ///
  /// In es, this message translates to:
  /// **'Tu usuario está bloqueado por varios intentos fallidos. Comunícate con soporte para desbloquearlo.'**
  String get loginLocked;

  /// No description provided for @usernameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu usuario'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get passwordRequired;

  /// No description provided for @createAccountLink.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Crea una'**
  String get createAccountLink;

  /// No description provided for @lockedFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu identidad.'**
  String get lockedFailed;

  /// No description provided for @biometricLogin.
  ///
  /// In es, this message translates to:
  /// **'Ingresar con huella o rostro'**
  String get biometricLogin;

  /// No description provided for @orDivider.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get orDivider;

  /// No description provided for @useAnotherAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No eres tú? Usar otra cuenta'**
  String get useAnotherAccount;

  /// No description provided for @biometricUnlockReason.
  ///
  /// In es, this message translates to:
  /// **'Desbloquea Nexo Bank'**
  String get biometricUnlockReason;

  /// No description provided for @biometricEnableReason.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para activarlo'**
  String get biometricEnableReason;

  /// No description provided for @onboardingStepPersonal.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get onboardingStepPersonal;

  /// No description provided for @onboardingStepCredentials.
  ///
  /// In es, this message translates to:
  /// **'Tu usuario'**
  String get onboardingStepCredentials;

  /// No description provided for @onboardingStepTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get onboardingStepTerms;

  /// No description provided for @onboardingStepWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get onboardingStepWelcome;

  /// No description provided for @onboardingStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @fullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullNameLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Cédula'**
  String get idNumberLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDateLabel;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: 0991234567 o +593991234567'**
  String get phoneHelper;

  /// No description provided for @usernameHelper.
  ///
  /// In es, this message translates to:
  /// **'Lo usarás para ingresar. Letras, números, \".\" o \"_\".'**
  String get usernameHelper;

  /// No description provided for @passwordHelper.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres, con al menos una letra y un número.'**
  String get passwordHelper;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirma la contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @createMyAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear mi cuenta'**
  String get createMyAccount;

  /// No description provided for @termsTitle.
  ///
  /// In es, this message translates to:
  /// **'Antes de terminar'**
  String get termsTitle;

  /// No description provided for @termsBody.
  ///
  /// In es, this message translates to:
  /// **'Al crear tu cuenta, Nexo Bank abrirá a tu nombre una cuenta de ahorros sin costo de mantenimiento. Tus datos se usan solo para identificarte y operar tus productos, se guardan cifrados y no se comparten con terceros sin tu autorización. Puedes cerrar tu cuenta en cualquier momento.'**
  String get termsBody;

  /// No description provided for @termsAccept.
  ///
  /// In es, this message translates to:
  /// **'Acepto los términos y condiciones y la política de privacidad'**
  String get termsAccept;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Listo, {name}!'**
  String welcomeTitle(String name);

  /// No description provided for @welcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de ahorros ya está abierta. Desde ahora puedes ingresar con tu usuario y contraseña.'**
  String get welcomeBody;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get start;

  /// No description provided for @regFullNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre completo'**
  String get regFullNameRequired;

  /// No description provided for @regFullNameSurname.
  ///
  /// In es, this message translates to:
  /// **'Ingresa nombre y apellido'**
  String get regFullNameSurname;

  /// No description provided for @regIdNumber.
  ///
  /// In es, this message translates to:
  /// **'La cédula debe tener 10 dígitos'**
  String get regIdNumber;

  /// No description provided for @regBirthDateRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige tu fecha de nacimiento'**
  String get regBirthDateRequired;

  /// No description provided for @regBirthDateFuture.
  ///
  /// In es, this message translates to:
  /// **'La fecha debe ser anterior a hoy'**
  String get regBirthDateFuture;

  /// No description provided for @regUnderage.
  ///
  /// In es, this message translates to:
  /// **'Debes ser mayor de edad'**
  String get regUnderage;

  /// No description provided for @regEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo'**
  String get regEmailRequired;

  /// No description provided for @regEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get regEmailInvalid;

  /// No description provided for @regPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'Teléfono no válido (9 a 15 dígitos)'**
  String get regPhoneInvalid;

  /// No description provided for @regUsernameInvalid.
  ///
  /// In es, this message translates to:
  /// **'Entre 3 y 30 letras, números, \".\" o \"_\"'**
  String get regUsernameInvalid;

  /// No description provided for @regPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {min} caracteres'**
  String regPasswordTooShort(int min);

  /// No description provided for @regPasswordWeak.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos una letra y un número'**
  String get regPasswordWeak;

  /// No description provided for @regPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get regPasswordMismatch;

  /// No description provided for @regTermsRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar los términos para continuar'**
  String get regTermsRequired;

  /// No description provided for @regUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ese usuario ya existe. Elige otro.'**
  String get regUsernameTaken;

  /// No description provided for @regServerInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa este dato'**
  String get regServerInvalid;

  /// No description provided for @onboardingUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar el registro en este momento. Intenta nuevamente en unos minutos.'**
  String get onboardingUnavailable;

  /// No description provided for @accountTypeSavings.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de ahorros'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeChecking.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corriente'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeGeneric.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get accountTypeGeneric;

  /// No description provided for @accountMain.
  ///
  /// In es, this message translates to:
  /// **'Principal'**
  String get accountMain;

  /// No description provided for @accountInactive.
  ///
  /// In es, this message translates to:
  /// **'No activa'**
  String get accountInactive;

  /// No description provided for @availableBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo disponible'**
  String get availableBalance;

  /// No description provided for @accountSemantics.
  ///
  /// In es, this message translates to:
  /// **'{name}, {type} terminada en {last4}. Saldo disponible {balance}'**
  String accountSemantics(
    String name,
    String type,
    String last4,
    String balance,
  );

  /// No description provided for @accountInactiveSuffix.
  ///
  /// In es, this message translates to:
  /// **'. Cuenta no activa'**
  String get accountInactiveSuffix;

  /// No description provided for @yourAccounts.
  ///
  /// In es, this message translates to:
  /// **'Tus cuentas'**
  String get yourAccounts;

  /// No description provided for @totalBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo total {amount}'**
  String totalBalance(String amount);

  /// No description provided for @noAccounts.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes cuentas.'**
  String get noAccounts;

  /// No description provided for @movementCredit.
  ///
  /// In es, this message translates to:
  /// **'Crédito'**
  String get movementCredit;

  /// No description provided for @movementDebit.
  ///
  /// In es, this message translates to:
  /// **'Débito'**
  String get movementDebit;

  /// No description provided for @movementIncoming.
  ///
  /// In es, this message translates to:
  /// **'ingreso'**
  String get movementIncoming;

  /// No description provided for @movementOutgoing.
  ///
  /// In es, this message translates to:
  /// **'egreso'**
  String get movementOutgoing;

  /// No description provided for @movementSemantics.
  ///
  /// In es, this message translates to:
  /// **'{description}, {kind} de {amount}, {time}'**
  String movementSemantics(
    String description,
    String kind,
    String amount,
    String time,
  );

  /// No description provided for @movementSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{time} · Saldo {balance}'**
  String movementSubtitle(String time, String balance);

  /// No description provided for @movementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get movementsTitle;

  /// No description provided for @noMovements.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta aún no tiene movimientos.'**
  String get noMovements;

  /// No description provided for @loadMoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar más. Reintentar'**
  String get loadMoreFailed;

  /// No description provided for @noMoreMovements.
  ///
  /// In es, this message translates to:
  /// **'No hay más movimientos'**
  String get noMoreMovements;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @segmentYoung.
  ///
  /// In es, this message translates to:
  /// **'Joven'**
  String get segmentYoung;

  /// No description provided for @segmentPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get segmentPremium;

  /// No description provided for @segmentEntrepreneur.
  ///
  /// In es, this message translates to:
  /// **'Emprendedor'**
  String get segmentEntrepreneur;

  /// No description provided for @segmentStandard.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get segmentStandard;

  /// No description provided for @customerSegment.
  ///
  /// In es, this message translates to:
  /// **'Cliente {segment}'**
  String customerSegment(String segment);

  /// No description provided for @emailTitle.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get emailTitle;

  /// No description provided for @phoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get phoneTitle;

  /// No description provided for @preferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tus transferencias'**
  String get notificationsSubtitle;

  /// No description provided for @promotions.
  ///
  /// In es, this message translates to:
  /// **'Promociones'**
  String get promotions;

  /// No description provided for @promotionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver ofertas en tu inicio'**
  String get promotionsSubtitle;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @biometricToggle.
  ///
  /// In es, this message translates to:
  /// **'Ingresar con huella o rostro'**
  String get biometricToggle;

  /// No description provided for @biometricToggleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo en este dispositivo'**
  String get biometricToggleSubtitle;

  /// No description provided for @saveFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio. {reason}'**
  String saveFailed(String reason);

  /// No description provided for @fxTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cambio'**
  String get fxTitle;

  /// No description provided for @fxReference.
  ///
  /// In es, this message translates to:
  /// **'Referencial · {age}'**
  String fxReference(String age);

  /// No description provided for @fxStale.
  ///
  /// In es, this message translates to:
  /// **'Referencial · no pudimos actualizar'**
  String get fxStale;

  /// No description provided for @promoSemantics.
  ///
  /// In es, this message translates to:
  /// **'Promoción: {text}'**
  String promoSemantics(String text);

  /// No description provided for @savingsSemantics.
  ///
  /// In es, this message translates to:
  /// **'{title}. Llevas {saved} de {target}, {percent} por ciento'**
  String savingsSemantics(
    String title,
    String saved,
    String target,
    int percent,
  );

  /// No description provided for @savingsProgress.
  ///
  /// In es, this message translates to:
  /// **'{saved} de {target}'**
  String savingsProgress(String saved, String target);

  /// No description provided for @quickActionTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferir'**
  String get quickActionTransfer;

  /// No description provided for @quickActionTopup.
  ///
  /// In es, this message translates to:
  /// **'Recargar celular'**
  String get quickActionTopup;

  /// No description provided for @quickActionGoals.
  ///
  /// In es, this message translates to:
  /// **'Mis metas'**
  String get quickActionGoals;

  /// No description provided for @quickActionInvest.
  ///
  /// In es, this message translates to:
  /// **'Inversiones'**
  String get quickActionInvest;

  /// No description provided for @quickActionAdvisor.
  ///
  /// In es, this message translates to:
  /// **'Mi asesor'**
  String get quickActionAdvisor;

  /// No description provided for @quickActionCollect.
  ///
  /// In es, this message translates to:
  /// **'Cobrar con QR'**
  String get quickActionCollect;

  /// No description provided for @quickActionSuppliers.
  ///
  /// In es, this message translates to:
  /// **'Pagar proveedores'**
  String get quickActionSuppliers;

  /// No description provided for @quickActionProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get quickActionProfile;

  /// No description provided for @transferTitle.
  ///
  /// In es, this message translates to:
  /// **'Transferir'**
  String get transferTitle;

  /// No description provided for @transferAction.
  ///
  /// In es, this message translates to:
  /// **'Transferir'**
  String get transferAction;

  /// No description provided for @transferBetweenMyAccounts.
  ///
  /// In es, this message translates to:
  /// **'Transferir entre mis cuentas'**
  String get transferBetweenMyAccounts;

  /// No description provided for @confirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirmTitle;

  /// No description provided for @receiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Comprobante'**
  String get receiptTitle;

  /// No description provided for @transferOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Las transferencias necesitan internet: no se guardan para enviarse después.'**
  String get transferOffline;

  /// No description provided for @transferNeedTwoAccounts.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos dos cuentas activas, y una con saldo, para transferir entre tus cuentas.'**
  String get transferNeedTwoAccounts;

  /// No description provided for @fromLabel.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In es, this message translates to:
  /// **'Hacia'**
  String get toLabel;

  /// No description provided for @amountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amountLabel;

  /// No description provided for @availableAmount.
  ///
  /// In es, this message translates to:
  /// **'Disponible: {amount}'**
  String availableAmount(String amount);

  /// No description provided for @descriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descriptionOptional;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @reviewBeforeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos antes de confirmar'**
  String get reviewBeforeConfirm;

  /// No description provided for @balanceAfter.
  ///
  /// In es, this message translates to:
  /// **'Saldo después'**
  String get balanceAfter;

  /// No description provided for @confirmTransfer.
  ///
  /// In es, this message translates to:
  /// **'Confirmar transferencia'**
  String get confirmTransfer;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @transferDone.
  ///
  /// In es, this message translates to:
  /// **'Transferencia realizada'**
  String get transferDone;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @receiptNumber.
  ///
  /// In es, this message translates to:
  /// **'Comprobante'**
  String get receiptNumber;

  /// No description provided for @backHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get backHome;

  /// No description provided for @anotherTransfer.
  ///
  /// In es, this message translates to:
  /// **'Hacer otra transferencia'**
  String get anotherTransfer;

  /// No description provided for @transferRejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'No se realizó la transferencia'**
  String get transferRejectedTitle;

  /// No description provided for @fixData.
  ///
  /// In es, this message translates to:
  /// **'Corregir datos'**
  String get fixData;

  /// No description provided for @transferUnknownTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el resultado'**
  String get transferUnknownTitle;

  /// No description provided for @transferUnknownBody.
  ///
  /// In es, this message translates to:
  /// **'La conexión se interrumpió y no sabemos si la transferencia se procesó. No la vuelvas a crear: toca \"Verificar estado\" y, si ya se hizo, verás el comprobante sin que se repita.'**
  String get transferUnknownBody;

  /// No description provided for @checkStatus.
  ///
  /// In es, this message translates to:
  /// **'Verificar estado'**
  String get checkStatus;

  /// No description provided for @goHome.
  ///
  /// In es, this message translates to:
  /// **'Ir al inicio'**
  String get goHome;

  /// No description provided for @transferSourceRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta de origen'**
  String get transferSourceRequired;

  /// No description provided for @transferSourceInactive.
  ///
  /// In es, this message translates to:
  /// **'La cuenta de origen no está activa'**
  String get transferSourceInactive;

  /// No description provided for @transferTargetRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta de destino'**
  String get transferTargetRequired;

  /// No description provided for @transferTargetSame.
  ///
  /// In es, this message translates to:
  /// **'El destino debe ser otra cuenta'**
  String get transferTargetSame;

  /// No description provided for @transferTargetInactive.
  ///
  /// In es, this message translates to:
  /// **'La cuenta de destino no está activa'**
  String get transferTargetInactive;

  /// No description provided for @transferCurrencyMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las cuentas tienen monedas distintas'**
  String get transferCurrencyMismatch;

  /// No description provided for @transferAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el monto'**
  String get transferAmountRequired;

  /// No description provided for @transferAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto válido, por ejemplo 25.50'**
  String get transferAmountInvalid;

  /// No description provided for @transferAmountNotPositive.
  ///
  /// In es, this message translates to:
  /// **'El monto debe ser mayor a cero'**
  String get transferAmountNotPositive;

  /// No description provided for @transferInsufficient.
  ///
  /// In es, this message translates to:
  /// **'Saldo insuficiente. Disponible: {amount}'**
  String transferInsufficient(String amount);

  /// No description provided for @rejectInsufficient.
  ///
  /// In es, this message translates to:
  /// **'Saldo insuficiente en {account}.'**
  String rejectInsufficient(String account);

  /// No description provided for @rejectAccountNotActive.
  ///
  /// In es, this message translates to:
  /// **'Una de las cuentas no está activa.'**
  String get rejectAccountNotActive;

  /// No description provided for @rejectSameAccount.
  ///
  /// In es, this message translates to:
  /// **'El origen y el destino deben ser cuentas distintas.'**
  String get rejectSameAccount;

  /// No description provided for @rejectCurrencyMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las cuentas tienen monedas distintas.'**
  String get rejectCurrencyMismatch;

  /// No description provided for @rejectAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos una de las cuentas.'**
  String get rejectAccountNotFound;

  /// No description provided for @transferNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta transferencia.'**
  String get transferNotFound;

  /// No description provided for @ownAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta propia'**
  String get ownAccount;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get statusPending;

  /// No description provided for @notificationTransferTitle.
  ///
  /// In es, this message translates to:
  /// **'Transferencia realizada'**
  String get notificationTransferTitle;

  /// No description provided for @notificationTransferBody.
  ///
  /// In es, this message translates to:
  /// **'Enviaste {amount} de {from} a {to}.'**
  String notificationTransferBody(String amount, String from, String to);

  /// No description provided for @notificationChannelName.
  ///
  /// In es, this message translates to:
  /// **'Transferencias'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tus transferencias'**
  String get notificationChannelDescription;

  /// No description provided for @greetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In es, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @aliasSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorros'**
  String get aliasSavings;

  /// No description provided for @aliasChecking.
  ///
  /// In es, this message translates to:
  /// **'Corriente'**
  String get aliasChecking;

  /// No description provided for @aliasInvestments.
  ///
  /// In es, this message translates to:
  /// **'Inversiones'**
  String get aliasInvestments;

  /// No description provided for @aliasBusiness.
  ///
  /// In es, this message translates to:
  /// **'Negocio'**
  String get aliasBusiness;

  /// No description provided for @aliasPersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get aliasPersonal;

  /// No description provided for @savingsGoal.
  ///
  /// In es, this message translates to:
  /// **'Meta de ahorro'**
  String get savingsGoal;

  /// No description provided for @promoSavingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gana 5% extra en tu primera meta'**
  String get promoSavingsTitle;

  /// No description provided for @promoSavingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo este mes'**
  String get promoSavingsSubtitle;

  /// No description provided for @promoAdvisorTitle.
  ///
  /// In es, this message translates to:
  /// **'Asesoría de inversiones sin costo'**
  String get promoAdvisorTitle;

  /// No description provided for @promoAdvisorSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda con tu asesor'**
  String get promoAdvisorSubtitle;

  /// No description provided for @promoCreditTitle.
  ///
  /// In es, this message translates to:
  /// **'Crédito para tu negocio'**
  String get promoCreditTitle;

  /// No description provided for @promoCreditSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pre-aprobado hasta {amount}'**
  String promoCreditSubtitle(String amount);

  /// No description provided for @promoTransfersTitle.
  ///
  /// In es, this message translates to:
  /// **'Black Friday Nexo'**
  String get promoTransfersTitle;

  /// No description provided for @promoTransfersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'0% de comisión en todas tus transferencias'**
  String get promoTransfersSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
