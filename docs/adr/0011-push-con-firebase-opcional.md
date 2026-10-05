# 0011. Notificaciones push con Firebase, opcional por entorno

**Estado:** aceptada

**En pocas palabras:** cuando hay una transferencia, el backend le envía al
cliente una notificación push con Firebase, aunque tenga la app cerrada.
Si Firebase no está configurado, la app funciona igual y solo muestra un
aviso local.

## Contexto
Quiero avisar al cliente de sus movimientos aunque no tenga la app
abierta. Hay dos tipos de aviso:

- **Notificación local:** la crea la propia app, así que solo aparece si
  la app está haciendo algo en ese momento.
- **Notificación push:** la envía el servidor, y llega con la app cerrada o
  por una transferencia hecha desde otro dispositivo.

El backend ya enviaba push por FCM (Firebase Cloud Messaging) con
`FcmPushSender` en ms-customer, y ya registraba los dispositivos. Faltaba
que la app obtuviera un token real de Firebase.

Por otro lado, Firebase necesita archivos propios de cada proyecto
(`google-services.json` y una cuenta de servicio). No quería que su
ausencia rompiera el CI ni impidiera compilar a quien clone el repo.

## Decisión
- **`FirebasePushService`** (infraestructura) implementa el puerto
  `PushTokenSource` con `firebase_messaging`. Pide el permiso de
  notificaciones al iniciar sesión, registra el token en
  `PUT /customers/me/devices` y lo vuelve a registrar si Firebase lo
  cambia.
- **Firebase es opcional.** El plugin de Gradle `google-services` solo se
  aplica si existe `android/app/google-services.json`. Al arrancar, la app
  intenta `Firebase.initializeApp()`; si falla, usa `NoPushTokenSource` y
  sigue con avisos locales. El backend hace lo mismo: sin
  `FCM_CREDENTIALS_FILE`, la push solo se escribe en el log.
- **El aviso se ve igual en cualquier estado de la app:**

  | Estado de la app | Quién muestra el aviso |
  |---|---|
  | Cerrada o en segundo plano | El sistema, con la push de Firebase |
  | Abierta | `ForegroundPushPresenter`, que la muestra como notificación local (Android no muestra push con la app abierta) |
  | Abierta, y la transferencia se hizo en ella | Primero el aviso local; cuando llega la push, usa **el mismo id** (`notificationIdFor(transferId)`) y lo reemplaza, así no se duplica |

- Tocar la notificación abre `app://transfers/{id}` (el detalle de la
  transferencia), tanto si la app estaba cerrada como abierta, con el
  mismo manejo de deep links que los avisos locales.
- Respeto la preferencia del cliente en los dos lados: ms-customer no
  envía la push si desactivó las notificaciones, y la app tampoco la
  muestra con la app abierta.

## Alternativas
- **Solo notificaciones locales:** no llegan con la app cerrada ni avisan
  de lo que pasa en otros canales.
- **Firebase obligatorio, con el archivo en el repositorio:** cualquier
  clon dependería de mi proyecto de Firebase, y el CI necesitaría el
  archivo.
- **`flutterfire configure` con `firebase_options.dart`:** genera código
  para cada proyecto. Con el plugin de Gradle basta con colocar el JSON.
- **Otro proveedor (OneSignal, APNs directo):** Firebase cubre Android e
  iOS, y el backend ya lo usaba.

## Consecuencias
- Para activar las push en un entorno hay que crear su proyecto en
  Firebase (es gratis), colocar `google-services.json` en la app y la
  cuenta de servicio en `app-backend/secrets/` (los pasos están en el
  README).
- En iOS también se necesitan `GoogleService-Info.plist` y una clave APNs
  en Firebase. Por ahora lo validé en Android.
- El texto de la push lo arma ms-customer en el idioma guardado en las
  preferencias del cliente; el del aviso local, la app en el idioma del
  teléfono. Por eso pueden diferir un poco.
