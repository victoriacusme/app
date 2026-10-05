# Entornos de la app

**Para desarrollar no necesitas estos archivos.** Sin ellos, la app elige
sola el backend según el dispositivo (ver `lib/core/config/env.dart`): en
un teléfono físico usa el túnel HTTPS, y en el emulador se conecta directo
a la PC.

Estos archivos sirven para fijar una URL concreta, que siempre tiene
prioridad. Se eligen al compilar:

```bash
flutter run --dart-define-from-file=config/staging.json
flutter build apk --release --dart-define-from-file=config/staging.json
```

| Archivo | Para qué sirve | Backend |
|---|---|---|
| `dev.json` | Emulador de Android | `http://10.0.2.2:8080` (así ve el emulador a la PC) |
| `staging.json` | Cualquier teléfono, en cualquier red | El túnel HTTPS fijo hacia el gateway local (perfil `tunnel` en `app-backend`) |
| `prod.json` | Producción | `https://api.nexo.ec`, con certificate pinning (`PIN_SHA256`) |

La URL de `staging.json` es la misma para todo el equipo y está versionada
aquí. Por eso un APK compilado con ella funciona en cualquier teléfono, sin
configurar nada más.

Las configuraciones de ejecución compartidas del IDE (`.run/` para Android
Studio o IntelliJ y `.vscode/launch.json`) ya ofrecen estos archivos como
opciones.
