# Nexo Bank: app móvil (Flutter)

App de banca para personas. Con ella el cliente puede:

- Iniciar sesión con usuario y contraseña, o con su huella o rostro.
- Crear una cuenta nueva.
- Ver sus cuentas, sus saldos y sus movimientos, incluso sin conexión.
- Transferir dinero entre sus propias cuentas.
- Consultar el tipo de cambio.
- Recibir una notificación después de cada transferencia.
- Cambiar sus preferencias (tema, notificaciones y promociones).

El home cambia según el tipo de cliente: lo decide el backend, sin publicar
una versión nueva de la app.

| Home joven (Ana) | Home premium (Carlos) | Home emprendedor (Lucía) | Movimientos | Confirmar transferencia |
|---|---|---|---|---|
| ![](docs/screenshots/02_home_joven_ana.png) | ![](docs/screenshots/07_home_premium_carlos.png) | ![](docs/screenshots/09_home_emprendedor_lucia.png) | ![](docs/screenshots/03_movimientos.png) | ![](docs/screenshots/05_transferencia_confirmar.png) |

Son capturas reales del emulador contra el backend (`docs/screenshots/`).
La misma app muestra un home distinto para cada segmento, y el tema oscuro
de Ana viene de las preferencias que tiene guardadas en el backend.

**Más documentación:** [decisiones de arquitectura (ADRs)](docs/adr/README.md) ·
[uso de IA](docs/AI_USAGE.md) · [cómo contribuir](CONTRIBUTING.md)

## Antes de empezar: qué instalar

### Obligatorio

| Herramienta | Versión | Para qué | Dónde conseguirla |
|---|---|---|---|
| Git | Cualquiera reciente | Clonar el repositorio | [git-scm.com](https://git-scm.com/downloads) |
| Flutter SDK | **3.47.6** (canal stable); incluye Dart 3.13 | Compilar y ejecutar la app | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| Android Studio | Reciente | Trae el Android SDK, el emulador y un JDK | [developer.android.com/studio](https://developer.android.com/studio) |
| Android SDK | Plataforma **Android 36** (API 36) y sus build-tools | Compilar para Android; la app funciona desde Android 7.0 (API 24) | Android Studio → *Settings → Languages & Frameworks → Android SDK* |
| JDK | **17 o superior** | Lo usa Gradle para compilar Android | Viene con Android Studio; o [Adoptium](https://adoptium.net) |
| Docker y Docker Compose | Docker 24+ y Compose v2+ | Levantar el backend (microservicios, gateway y bases de datos) | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |

En Android Studio instala también los plugins **Flutter** y **Dart**
(*Settings → Plugins*). Si prefieres VS Code, instala la extensión
**Flutter**.

### Opcional

| Herramienta | Cuándo la necesitas |
|---|---|
| Un emulador de Android | Para probar sin teléfono. Créalo en Android Studio → *Device Manager* (por ejemplo, un Pixel con Android 14 o superior) |
| Cuenta gratuita de [ngrok](https://ngrok.com) | Para probar en un **teléfono físico**: el túnel que conecta el teléfono con el backend de tu PC. Los pasos están en `app-backend/.env.example` |
| Proyecto de [Firebase](https://console.firebase.google.com) | Para recibir **notificaciones push** reales (ver [Notificaciones](#notificaciones)). Sin él la app funciona igual |
| macOS con Xcode y CocoaPods | Solo para ejecutar en **iOS**; el simulador de iOS no existe en Windows ni Linux |

### Comprobar la instalación

```bash
flutter --version    # debe decir Flutter 3.47.6
flutter doctor       # revisa Android SDK, licencias, IDE y dispositivos
docker compose version
```

Si `flutter doctor` pide aceptar licencias de Android, ejecuta
`flutter doctor --android-licenses` y acepta todas.

## Ejecutar

1. **Levanta el backend.** En la carpeta `app-backend`:

   ```bash
   docker compose up -d
   ```

   Para usar un teléfono físico, levántalo con el túnel:
   `docker compose --profile tunnel up -d`.

2. **Abre un emulador o conecta tu teléfono** con la depuración USB
   activada. Comprueba que aparezca con `flutter devices`.

3. **Ejecuta la app.** En la carpeta `app`:

   ```bash
   flutter pub get
   flutter run
   ```

   También funciona el botón **Run** del IDE, sin configurar nada.

### ¿A qué backend se conecta?

La app elige el backend sola, según dónde se ejecuta:

| Dónde corre la app | Backend que usa |
|---|---|
| Teléfono físico (por WiFi o datos) | Túnel HTTPS fijo `https://ragweed-onshore-correct.ngrok-free.dev`, que llega al gateway de la PC |
| Emulador de Android | `http://10.0.2.2:8080` (así ve el emulador a la PC) |
| Simulador de iOS | `http://localhost:8080` |

Al arrancar, la consola muestra cuál eligió: `Backend (staging|dev): <url>`.

Para usar un **teléfono físico**, el túnel tiene que estar levantado en la
PC junto con el backend: en `app-backend`, `docker compose --profile tunnel
up -d`.

Ese dominio del túnel pertenece a una cuenta de ngrok. Si clonas el
proyecto en otra PC, crea tu propia cuenta gratuita, reclama tu dominio
estático (los pasos están en `app-backend/.env.example`) y reemplaza la
URL en dos lugares: `stagingUrl` en `lib/core/config/env.dart` y
`config/staging.json`.

Si necesitas una URL fija, por ejemplo para producción o para un APK de
pruebas, usa un archivo de `config/`. Esa URL siempre tiene prioridad (ver
[config/README.md](config/README.md)):

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

En producción, además, se activa el certificate pinning
([ADR 0009](docs/adr/0009-certificate-pinning-spki.md)):

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.nexo.ec \
  --dart-define=PIN_SHA256=<pin actual>,<pin de respaldo>
```

En modo debug se permite HTTP sin cifrar, para usar el backend local. Las
versiones release exigen HTTPS.

### Usuarios de prueba

| Usuario | Segmento | Contraseña |
|---|---|---|
| `ana` | Joven | `Nexo2026*` |
| `carlos` | Premium | `Nexo2026*` |
| `lucia` | Emprendedora | `Nexo2026*` |

Cada uno ve un home distinto. También puedes crear una cuenta nueva con
**"Abrir cuenta"** en el login.

## Pruebas

```bash
flutter analyze   # análisis estático
flutter test      # tests unitarios, de Bloc, de widgets y golden
```

### De punta a punta (E2E)

Se ejecutan en un emulador o teléfono, contra el backend real. Para ver
los dispositivos conectados: `flutter devices`.

```bash
flutter test integration_test/login_movements_test.dart \
  integration_test/own_transfer_test.dart \
  integration_test/register_test.dart \
  integration_test/promotions_test.dart -d emulator-5554
```

| Archivo | Qué recorre |
|---|---|
| `login_movements_test.dart` | Login → home → movimientos |
| `own_transfer_test.dart` | Login → transferencia propia → los saldos cambian (al final devuelve el dinero) |
| `register_test.dart` | Crear cuenta → entra al home (crea un usuario nuevo en cada ejecución) |
| `promotions_test.dart` | Desactivar las promociones en el perfil → desaparecen del home |

### Otras pruebas

```bash
# Contrato contra el backend real, a través del gateway.
# Mueve $1,00 entre cuentas de `carlos` y lo devuelve.
CONTRACT_BASE_URL=http://localhost:8080 flutter test test/contract
# Lo mismo, incluyendo el registro (crea un usuario nuevo en cada ejecución)
CONTRACT_BASE_URL=http://localhost:8080 CONTRACT_REGISTER=1 flutter test test/contract

# Resiliencia con Toxiproxy: latencia → caída → circuito abierto →
# recuperación. Al terminar deja Toxiproxy como estaba.
CHAOS_BASE_URL=http://localhost:8080 flutter test test/chaos

# Volver a generar las capturas de docs/screenshots
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart -d emulator-5554

# Volver a generar las imágenes de referencia (golden) del home
flutter test --update-goldens test/features/experience/sdui_golden_test.dart
```

## Flujo de trabajo

Uso Trunk Based Development y Conventional Commits; los detalles están en
[CONTRIBUTING.md](CONTRIBUTING.md).

## Estructura

Cada funcionalidad tiene su carpeta, y dentro de ella separo la lógica del
negocio de los detalles técnicos
([ADR 0001](docs/adr/0001-hexagonal-por-feature.md)).

```
lib/
├── app/            arranque, rutas, dependencias, sesión, ajustes y bloqueo con huella
├── core/           piezas comunes: configuración, red (Dio, interceptores, pinning),
│                   seguridad (tokens, JWE, biometría), caché cifrada, conectividad,
│                   dinero, deep links y manejo de errores
├── design_system/  tema, colores y widgets reutilizables (skeleton, banners, estados)
├── l10n/           traducciones (español e inglés)
└── features/
    ├── auth/           login y crear cuenta (registro en 4 pasos)
    ├── accounts/       cuentas y movimientos
    ├── transfers/      formulario, confirmación y comprobante
    ├── customer/       perfil y preferencias
    ├── experience/     home dinámico (SDUI) y sus componentes
    ├── fx/             tipo de cambio (servicio externo)
    └── notifications/  push con Firebase, avisos locales y deep links
test/               unit · bloc · widget · golden · contract · chaos
integration_test/   pruebas E2E y capturas
docs/               ADRs, uso de IA y capturas
```

## Home dinámico (SDUI)

En lugar de tener un home fijo, la app le pregunta al backend qué mostrar
([ADR 0005](docs/adr/0005-sdui.md)). `GET /experience/home` devuelve una
lista de componentes según el segmento del cliente, la hora y sus
preferencias. La app la recorre en orden, y el `ComponentRegistry`
convierte cada `type` en un widget:

| `type` | Qué muestra | De dónde saca sus datos |
|---|---|---|
| `greeting` | Saludo según la hora | Perfil del cliente |
| `accounts_summary` | Cuentas y saldo total | `AccountsBloc` |
| `quick_actions` | Accesos directos | — |
| `savings_goal` | Avance de una meta de ahorro | `AccountsBloc` |
| `promo_banner` | Una promoción | — |
| `fx_rates` | Tipo de cambio | `FxCubit` |

- Si llega un `type` que la app no conoce, o con datos inválidos, **lo
  ignora**. Así el backend puede publicar componentes nuevos sin romper las
  versiones viejas de la app.
- Guardo el último home en caché y lo revalido con `ETag`: si no cambió, el
  backend responde 304 sin volver a enviarlo.
- Si ms-customer no responde y no hay caché, uso el home de respaldo que
  viene en la app (`assets/experience/home_fallback_es.json` y `_en.json`).
- Cada sección falla por separado: si cae el tipo de cambio, esa sección se
  oculta; si cae ms-accounts, las cuentas muestran lo guardado.

Enlaces internos que entiende la app: `app://transfers`,
`app://transfers/{id}`, `app://accounts/{id}`, `app://profile` y
`app://home`. Cualquier otro muestra "Esta función estará disponible
pronto".

## Idiomas (español e inglés)

Toda la app está traducida con `gen-l10n`, en `lib/l10n/app_es.arb` y
`app_en.arb`.

- **La app usa el idioma del teléfono.** Toma el primero de la lista de
  idiomas del teléfono que la app soporte; si no soporta ninguno, usa
  español. No hay selector de idioma dentro de la app: si el cliente cambia
  el idioma del teléfono, la app cambia al instante. Además, le informa ese
  idioma al backend para que las push lleguen en el mismo idioma.
- Los montos (`$1.250,50` / `$1,250.50`), las fechas, los textos para
  lectores de pantalla y las notificaciones siguen el idioma activo.
- Los errores del backend se traducen por su `code`. Nunca muestro su
  `detail`, porque siempre llega en español.
- Cada petición lleva el encabezado `Accept-Language`.
- **Los textos de la interfaz son siempre de la app.** Del backend solo
  muestro los **nombres** (del cliente, de sus cuentas y de sus metas) y
  los datos sensibles, que llegan enmascarados:
  - **Saludo:** lo arma la app con la hora del teléfono ("Buenas tardes" /
    "Good afternoon") y el nombre del perfil.
  - **Cuentas:** si no tienen alias, muestro el tipo traducido. Los alias
    genéricos del banco ("Ahorros", "Corriente", "Cuenta de ahorros",
    "Inversiones"…) también se traducen, pero solo si coinciden con el tipo
    de cuenta ("Ahorros" solo en una cuenta de ahorros). Un alias que puso
    el cliente ("Meta: viaje") se respeta tal cual.
  - **Home:** los títulos de las secciones, los accesos directos (por su
    `id`), el encabezado "Meta de ahorro" y las promociones conocidas (por
    su destino) usan textos de la app. Una campaña nueva que la app no
    conoce muestra el texto del backend, que puede venir en los dos
    idiomas: `"title": {"es": "...", "en": "..."}`.

Para agregar un texto nuevo: añádelo en los dos `.arb` y úsalo con
`context.l10n.<clave>`.

## Seguridad

| Medida | Qué hace | ADR |
|---|---|---|
| Login cifrado con JWE | El usuario y la contraseña viajan cifrados (RSA-OAEP-256 + A256GCM) con la clave pública de ms-auth; nunca van en texto plano | [0008](docs/adr/0008-login-con-jwe.md) |
| Certificate pinning | En producción, la app solo acepta el servidor si su clave pública está en la lista `PIN_SHA256` | [0009](docs/adr/0009-certificate-pinning-spki.md) |
| Tokens | Se guardan solo en Keychain (iOS) o Keystore (Android). Si vencen, se renuevan una sola vez y las demás peticiones esperan | — |
| Caché cifrada | Hive con AES-256; se borra al cerrar sesión | [0003](docs/adr/0003-hive-ce-cifrado.md) |
| Biometría | Opcional y por teléfono: el login ofrece "Ingresar con huella o rostro" junto a usuario y contraseña | [0010](docs/adr/0010-biometria-y-privacidad.md) |
| Privacidad | En la vista de apps abiertas no se ve el contenido; en Android release tampoco se pueden tomar capturas (`FLAG_SECURE`) | [0010](docs/adr/0010-biometria-y-privacidad.md) |
| Datos enmascarados | El backend ya envía enmascarados los números de cuenta (`****4521`), la cédula y el teléfono | — |
| Dinero | Cada transferencia lleva su `Idempotency-Key`; nunca se reintenta sola ni se guarda para enviarla sin conexión | [0006](docs/adr/0006-dinero-sin-conexion.md) |

## Notificaciones

Después de cada transferencia, ms-customer envía una **notificación push
con Firebase Cloud Messaging**. Llega con la app cerrada, en segundo plano
o abierta, e incluso si la transferencia se hizo desde otro dispositivo. Al
tocarla se abre el detalle de la transferencia. Si el cliente desactivó las
notificaciones en su perfil, no se envía, y en la pantalla de bloqueo no se
muestra el contenido.

Firebase es **opcional** ([ADR 0011](docs/adr/0011-push-con-firebase-opcional.md)):
sin configurarlo, la app compila igual y muestra un aviso local después de
cada transferencia hecha en ella.

Para activar las push (se hace una sola vez, toma unos 10 minutos):

1. En [Firebase Console](https://console.firebase.google.com), crea un
   proyecto y agrega una app **Android** con el paquete `ec.nexo.nexo_bank`.
2. Descarga `google-services.json` y cópialo en `android/app/`. Está en
   `.gitignore`, así que no se sube al repositorio.
3. En el proyecto de Firebase, ve a *Configuración → Cuentas de servicio →
   Generar nueva clave privada*. Guarda ese JSON en
   `app-backend/secrets/firebase-adminsdk.json` y agrega esta línea en
   `app-backend/.env`:
   `FCM_CREDENTIALS_FILE=/run/secrets/nexo/firebase-adminsdk.json`.
4. Reinicia ms-customer (`docker compose up -d ms-customer` en
   `app-backend`) y ejecuta la app con `flutter run`.

Para probarla: inicia sesión y acepta el permiso de notificaciones, cierra
la app y haz una transferencia desde otro lado, por ejemplo con `curl` al
gateway (ver el README del backend). La notificación llega a la bandeja.

## Resiliencia

Así se comporta la app cuando la red o el backend fallan
([ADR 0004](docs/adr/0004-stale-while-revalidate.md)):

- **Primero lo guardado, después lo nuevo:** cuentas y movimientos se
  muestran al instante desde la caché cifrada y luego se actualizan. Si el
  backend falla, los datos guardados siguen visibles con el aviso "No
  pudimos actualizar".
- **Reintentos:** solo en lecturas (GET), hasta 3 intentos, esperando cada
  vez un poco más.
- **Circuit breaker:** si un servicio falla 5 veces seguidas, la app deja
  de llamarlo durante 30 segundos y luego prueba con una sola petición.
- **Sin conexión:** aparece un aviso en toda la app, y al volver la red
  todo se actualiza solo.
- **Transferencias:** nunca se reintentan ni se guardan para después. La
  `Idempotency-Key` se crea al confirmar; si la respuesta no llega,
  "Verificar estado" reenvía la misma clave y el backend devuelve el
  resultado original sin duplicar el movimiento
  ([ADR 0006](docs/adr/0006-dinero-sin-conexion.md)).
- Al cerrar sesión se borran los tokens y la caché.
