// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Nexo Bank';

  @override
  String get loading => 'Cargando';

  @override
  String get loadingMore => 'Cargando más';

  @override
  String get retry => 'Reintentar';

  @override
  String supportCode(String code) {
    return 'Código de soporte: $code';
  }

  @override
  String get continueAction => 'Continuar';

  @override
  String get comingSoon => 'Esta función estará disponible pronto.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String buttonLoading(String label) {
    return '$label, cargando';
  }

  @override
  String get offlineBanner =>
      'Sin conexión. Verás los últimos datos guardados.';

  @override
  String staleRefreshFailed(String age) {
    return 'No pudimos actualizar. Mostrando datos de $age.';
  }

  @override
  String staleRefreshing(String age) {
    return 'Datos de $age. Actualizando…';
  }

  @override
  String get relativeNow => 'hace un momento';

  @override
  String relativeMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String relativeHours(int count) {
    return 'hace $count h';
  }

  @override
  String relativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String moneySpeechUsd(int units, int cents) {
    return '$units dólares con $cents centavos';
  }

  @override
  String moneySpeechOther(int units, int cents, String currency) {
    return '$units $currency con $cents centavos';
  }

  @override
  String moneySpeechNegative(String amount) {
    return 'menos $amount';
  }

  @override
  String maxChars(int max) {
    return 'Máximo $max caracteres';
  }

  @override
  String get errorNetwork => 'No pudimos conectarnos. Revisa tu conexión.';

  @override
  String get errorTimeout => 'El servidor tardó demasiado en responder.';

  @override
  String get errorServiceUnavailable =>
      'El servicio no está disponible en este momento. Intenta nuevamente en unos segundos.';

  @override
  String get errorRateLimited =>
      'Demasiadas solicitudes. Espera un momento e intenta nuevamente.';

  @override
  String get errorSession => 'Tu sesión no es válida. Ingresa nuevamente.';

  @override
  String get errorValidation => 'Revisa los datos ingresados.';

  @override
  String get errorNotFound => 'No encontramos lo que buscabas.';

  @override
  String get errorUnexpected =>
      'Ocurrió un error inesperado. Intenta nuevamente.';

  @override
  String get loginWelcome => 'Bienvenido a Nexo';

  @override
  String get loginSessionExpired => 'Tu sesión expiró. Ingresa nuevamente.';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginSubmit => 'Ingresar';

  @override
  String get loginInvalidCredentials => 'Usuario o contraseña incorrectos.';

  @override
  String get loginLocked =>
      'Tu usuario está bloqueado por varios intentos fallidos. Comunícate con soporte para desbloquearlo.';

  @override
  String get usernameRequired => 'Ingresa tu usuario';

  @override
  String get passwordRequired => 'Ingresa tu contraseña';

  @override
  String get createAccountLink => '¿No tienes cuenta? Crea una';

  @override
  String get lockedTitle => 'Nexo Bank está bloqueado';

  @override
  String get lockedFailed => 'No pudimos verificar tu identidad.';

  @override
  String get lockedHint => 'Usa tu huella o rostro para continuar.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get lockedUsePassword => 'Ingresar con mi contraseña';

  @override
  String get biometricUnlockReason => 'Desbloquea Nexo Bank';

  @override
  String get biometricEnableReason => 'Confirma tu identidad para activarlo';

  @override
  String get onboardingStepPersonal => 'Tus datos';

  @override
  String get onboardingStepCredentials => 'Tu usuario';

  @override
  String get onboardingStepTerms => 'Términos';

  @override
  String get onboardingStepWelcome => 'Bienvenido';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get idNumberLabel => 'Cédula';

  @override
  String get birthDateLabel => 'Fecha de nacimiento';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get phoneLabel => 'Celular';

  @override
  String get phoneHelper => 'Ejemplo: 0991234567 o +593991234567';

  @override
  String get usernameHelper =>
      'Lo usarás para ingresar. Letras, números, \".\" o \"_\".';

  @override
  String get passwordHelper =>
      'Mínimo 8 caracteres, con al menos una letra y un número.';

  @override
  String get confirmPasswordLabel => 'Confirma la contraseña';

  @override
  String get createMyAccount => 'Crear mi cuenta';

  @override
  String get termsTitle => 'Antes de terminar';

  @override
  String get termsBody =>
      'Al crear tu cuenta, Nexo Bank abrirá a tu nombre una cuenta de ahorros sin costo de mantenimiento. Tus datos se usan solo para identificarte y operar tus productos, se guardan cifrados y no se comparten con terceros sin tu autorización. Puedes cerrar tu cuenta en cualquier momento.';

  @override
  String get termsAccept =>
      'Acepto los términos y condiciones y la política de privacidad';

  @override
  String welcomeTitle(String name) {
    return '¡Listo, $name!';
  }

  @override
  String get welcomeBody =>
      'Tu cuenta de ahorros ya está abierta. Desde ahora puedes ingresar con tu usuario y contraseña.';

  @override
  String get start => 'Comenzar';

  @override
  String get regFullNameRequired => 'Ingresa tu nombre completo';

  @override
  String get regFullNameSurname => 'Ingresa nombre y apellido';

  @override
  String get regIdNumber => 'La cédula debe tener 10 dígitos';

  @override
  String get regBirthDateRequired => 'Elige tu fecha de nacimiento';

  @override
  String get regBirthDateFuture => 'La fecha debe ser anterior a hoy';

  @override
  String get regUnderage => 'Debes ser mayor de edad';

  @override
  String get regEmailRequired => 'Ingresa tu correo';

  @override
  String get regEmailInvalid => 'Correo no válido';

  @override
  String get regPhoneInvalid => 'Teléfono no válido (9 a 15 dígitos)';

  @override
  String get regUsernameInvalid =>
      'Entre 3 y 30 letras, números, \".\" o \"_\"';

  @override
  String regPasswordTooShort(int min) {
    return 'Mínimo $min caracteres';
  }

  @override
  String get regPasswordWeak => 'Debe tener al menos una letra y un número';

  @override
  String get regPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get regTermsRequired => 'Debes aceptar los términos para continuar';

  @override
  String get regUsernameTaken => 'Ese usuario ya existe. Elige otro.';

  @override
  String get regServerInvalid => 'Revisa este dato';

  @override
  String get onboardingUnavailable =>
      'No pudimos completar el registro en este momento. Intenta nuevamente en unos minutos.';

  @override
  String get accountTypeSavings => 'Cuenta de ahorros';

  @override
  String get accountTypeChecking => 'Cuenta corriente';

  @override
  String get accountTypeGeneric => 'Cuenta';

  @override
  String get accountMain => 'Principal';

  @override
  String get accountInactive => 'No activa';

  @override
  String get availableBalance => 'Saldo disponible';

  @override
  String accountSemantics(
    String name,
    String type,
    String last4,
    String balance,
  ) {
    return '$name, $type terminada en $last4. Saldo disponible $balance';
  }

  @override
  String get accountInactiveSuffix => '. Cuenta no activa';

  @override
  String get yourAccounts => 'Tus cuentas';

  @override
  String totalBalance(String amount) {
    return 'Saldo total $amount';
  }

  @override
  String get noAccounts => 'Todavía no tienes cuentas.';

  @override
  String get movementCredit => 'Crédito';

  @override
  String get movementDebit => 'Débito';

  @override
  String get movementIncoming => 'ingreso';

  @override
  String get movementOutgoing => 'egreso';

  @override
  String movementSemantics(
    String description,
    String kind,
    String amount,
    String time,
  ) {
    return '$description, $kind de $amount, $time';
  }

  @override
  String movementSubtitle(String time, String balance) {
    return '$time · Saldo $balance';
  }

  @override
  String get movementsTitle => 'Movimientos';

  @override
  String get noMovements => 'Esta cuenta aún no tiene movimientos.';

  @override
  String get loadMoreFailed => 'No pudimos cargar más. Reintentar';

  @override
  String get noMoreMovements => 'No hay más movimientos';

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String get segmentYoung => 'Joven';

  @override
  String get segmentPremium => 'Premium';

  @override
  String get segmentEntrepreneur => 'Emprendedor';

  @override
  String get segmentStandard => 'Personas';

  @override
  String customerSegment(String segment) {
    return 'Cliente $segment';
  }

  @override
  String get emailTitle => 'Correo';

  @override
  String get phoneTitle => 'Celular';

  @override
  String get preferences => 'Preferencias';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsSubtitle => 'Avisos de tus transferencias';

  @override
  String get promotions => 'Promociones';

  @override
  String get promotionsSubtitle => 'Ver ofertas en tu inicio';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get biometricToggle => 'Ingresar con huella o rostro';

  @override
  String get biometricToggleSubtitle => 'Solo en este dispositivo';

  @override
  String saveFailed(String reason) {
    return 'No pudimos guardar el cambio. $reason';
  }

  @override
  String get fxTitle => 'Tipo de cambio';

  @override
  String fxReference(String age) {
    return 'Referencial · $age';
  }

  @override
  String get fxStale => 'Referencial · no pudimos actualizar';

  @override
  String promoSemantics(String text) {
    return 'Promoción: $text';
  }

  @override
  String savingsSemantics(
    String title,
    String saved,
    String target,
    int percent,
  ) {
    return '$title. Llevas $saved de $target, $percent por ciento';
  }

  @override
  String savingsProgress(String saved, String target) {
    return '$saved de $target';
  }

  @override
  String get quickActionTransfer => 'Transferir';

  @override
  String get quickActionTopup => 'Recargar celular';

  @override
  String get quickActionGoals => 'Mis metas';

  @override
  String get quickActionInvest => 'Inversiones';

  @override
  String get quickActionAdvisor => 'Mi asesor';

  @override
  String get quickActionCollect => 'Cobrar con QR';

  @override
  String get quickActionSuppliers => 'Pagar proveedores';

  @override
  String get quickActionProfile => 'Mi perfil';

  @override
  String get transferTitle => 'Transferir';

  @override
  String get transferAction => 'Transferir';

  @override
  String get transferBetweenMyAccounts => 'Transferir entre mis cuentas';

  @override
  String get confirmTitle => 'Confirmar';

  @override
  String get receiptTitle => 'Comprobante';

  @override
  String get transferOffline =>
      'Sin conexión. Las transferencias necesitan internet: no se guardan para enviarse después.';

  @override
  String get transferNeedTwoAccounts =>
      'Necesitas al menos dos cuentas activas, y una con saldo, para transferir entre tus cuentas.';

  @override
  String get fromLabel => 'Desde';

  @override
  String get toLabel => 'Hacia';

  @override
  String get amountLabel => 'Monto';

  @override
  String availableAmount(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String get description => 'Descripción';

  @override
  String get reviewBeforeConfirm => 'Revisa los datos antes de confirmar';

  @override
  String get balanceAfter => 'Saldo después';

  @override
  String get confirmTransfer => 'Confirmar transferencia';

  @override
  String get edit => 'Editar';

  @override
  String get transferDone => 'Transferencia realizada';

  @override
  String get date => 'Fecha';

  @override
  String get receiptNumber => 'Comprobante';

  @override
  String get backHome => 'Volver al inicio';

  @override
  String get anotherTransfer => 'Hacer otra transferencia';

  @override
  String get transferRejectedTitle => 'No se realizó la transferencia';

  @override
  String get fixData => 'Corregir datos';

  @override
  String get transferUnknownTitle => 'No pudimos confirmar el resultado';

  @override
  String get transferUnknownBody =>
      'La conexión se interrumpió y no sabemos si la transferencia se procesó. No la vuelvas a crear: toca \"Verificar estado\" y, si ya se hizo, verás el comprobante sin que se repita.';

  @override
  String get checkStatus => 'Verificar estado';

  @override
  String get goHome => 'Ir al inicio';

  @override
  String get transferSourceRequired => 'Elige la cuenta de origen';

  @override
  String get transferSourceInactive => 'La cuenta de origen no está activa';

  @override
  String get transferTargetRequired => 'Elige la cuenta de destino';

  @override
  String get transferTargetSame => 'El destino debe ser otra cuenta';

  @override
  String get transferTargetInactive => 'La cuenta de destino no está activa';

  @override
  String get transferCurrencyMismatch => 'Las cuentas tienen monedas distintas';

  @override
  String get transferAmountRequired => 'Ingresa el monto';

  @override
  String get transferAmountInvalid =>
      'Ingresa un monto válido, por ejemplo 25.50';

  @override
  String get transferAmountNotPositive => 'El monto debe ser mayor a cero';

  @override
  String transferInsufficient(String amount) {
    return 'Saldo insuficiente. Disponible: $amount';
  }

  @override
  String rejectInsufficient(String account) {
    return 'Saldo insuficiente en $account.';
  }

  @override
  String get rejectAccountNotActive => 'Una de las cuentas no está activa.';

  @override
  String get rejectSameAccount =>
      'El origen y el destino deben ser cuentas distintas.';

  @override
  String get rejectCurrencyMismatch => 'Las cuentas tienen monedas distintas.';

  @override
  String get rejectAccountNotFound => 'No encontramos una de las cuentas.';

  @override
  String get transferNotFound => 'No encontramos esta transferencia.';

  @override
  String get ownAccount => 'Cuenta propia';

  @override
  String get status => 'Estado';

  @override
  String get statusCompleted => 'Completada';

  @override
  String get statusPending => 'En revisión';

  @override
  String get notificationTransferTitle => 'Transferencia realizada';

  @override
  String notificationTransferBody(String amount, String from, String to) {
    return 'Enviaste $amount de $from a $to.';
  }

  @override
  String get notificationChannelName => 'Transferencias';

  @override
  String get notificationChannelDescription => 'Avisos de tus transferencias';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get aliasSavings => 'Ahorros';

  @override
  String get aliasChecking => 'Corriente';

  @override
  String get aliasInvestments => 'Inversiones';

  @override
  String get aliasBusiness => 'Negocio';

  @override
  String get aliasPersonal => 'Personal';

  @override
  String get savingsGoal => 'Meta de ahorro';

  @override
  String get promoSavingsTitle => 'Gana 5% extra en tu primera meta';

  @override
  String get promoSavingsSubtitle => 'Solo este mes';

  @override
  String get promoAdvisorTitle => 'Asesoría de inversiones sin costo';

  @override
  String get promoAdvisorSubtitle => 'Agenda con tu asesor';

  @override
  String get promoCreditTitle => 'Crédito para tu negocio';

  @override
  String promoCreditSubtitle(String amount) {
    return 'Pre-aprobado hasta $amount';
  }

  @override
  String get promoTransfersTitle => 'Black Friday Nexo';

  @override
  String get promoTransfersSubtitle =>
      '0% de comisión en todas tus transferencias';
}
