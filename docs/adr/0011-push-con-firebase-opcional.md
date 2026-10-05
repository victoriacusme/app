# 0011. Notificaciones push con Firebase, opcional por entorno

**Estado:** aceptada

## Contexto
La prueba pide notificaciones push. Una notificación local solo aparece si
la app ejecuta el flujo en ese momento; una push la envía el servidor y
llega con la app cerrada o desde otro dispositivo (p. ej. una transferencia
hecha por otro canal). El backend ya tenía el envío por FCM (`FcmPushSender`
en ms-customer) y el registro de tokens; faltaba el token real en la app.

A la vez, Firebase exige archivos por proyecto (`google-services.json`,
cuenta de servicio) que no deben bloquear el CI ni a quien clone el repo.

## Decisión
- **`FirebasePushService`** (infraestructura) implementa el puerto
  `PushTokenSource` con `firebase_messaging`: pide el permiso de
  notificaciones al iniciar sesión, registra el token en
  `PUT /customers/me/devices` y lo vuelve a registrar si FCM lo rota.
- **Firebase es opcional.** El plugin de Gradle `google-services` se aplica
  solo si existe `android/app/google-services.json`, y
  `Firebase.initializeApp()` se intenta al arrancar: si falla, se usa
  `NoPushTokenSource` y la app queda como antes (solo avisos locales). El
  backend hace lo mismo: sin `FCM_CREDENTIALS_FILE`, la push va al log.
- **Tres estados de la app, una sola experiencia:**

  | App | Quién muestra el aviso |
  |---|---|
  | Cerrada o en segundo plano | El sistema, con la push de FCM |
  | Abierta | `ForegroundPushPresenter` la muestra como notificación local (Android no muestra push en primer plano) |
  | Abierta y la transferencia se hizo aquí | El aviso local inmediato; la push llega después con **el mismo id** (`notificationIdFor(transferId)`) y lo reemplaza, sin duplicar |

- Tocar la push abre `app://transfers/{id}` (detalle de la transferencia),
  en frío o en caliente, por el mismo flujo de deep links que los avisos
  locales.
- Se respeta la preferencia del cliente en los dos lados: ms-customer no
  envía si están desactivadas y la app no presenta la push en primer plano.

## Alternativas
- **Solo notificaciones locales:** no cumple "push" (no llega con la app
  cerrada ni por eventos de otros canales).
- **Firebase obligatorio (archivo versionado):** cualquier clon dependería de
  nuestro proyecto de Firebase y el CI necesitaría el archivo.
- **`flutterfire configure` con `firebase_options.dart`:** genera código por
  proyecto; con el plugin de Gradle basta con colocar el JSON.
- **Otro proveedor (OneSignal, APNs directo):** FCM cubre Android e iOS y el
  backend ya lo usaba.

## Consecuencias
- Para la demo hay que crear un proyecto en Firebase (gratis), colocar
  `google-services.json` en la app y la cuenta de servicio en
  `app-backend/secrets/` (ver README).
- En iOS además se necesita `GoogleService-Info.plist` y una clave APNs en
  Firebase; la demo se hace en Android.
- El texto de la push lo arma ms-customer en el idioma de las preferencias
  del cliente; el aviso local, la app. Por eso pueden diferir levemente.
