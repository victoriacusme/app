# Entornos de la app

**No hace falta usarlos para desarrollar:** sin archivo, la app elige sola
el backend según el dispositivo (ver `lib/core/config/env.dart`): teléfono
físico → túnel HTTPS, emulador → PC directo.

Estos archivos fijan una URL explícita, que siempre manda. Se elige al
compilar:

```bash
flutter run --dart-define-from-file=config/staging.json
flutter build apk --release --dart-define-from-file=config/staging.json
```

| Archivo | Para qué | Backend |
|---|---|---|
| `dev.json` | Emulador de Android | `http://10.0.2.2:8080` (la PC vista desde el emulador) |
| `staging.json` | **Cualquier teléfono, en cualquier red** | Túnel HTTPS fijo hacia el gateway local (ver `app-backend`, perfil `tunnel`) |
| `prod.json` | Producción | `https://api.nexo.ec` con certificate pinning (`PIN_SHA256`) |

Para que todos los teléfonos funcionen sin configurar nada se usa
**staging**: la URL es la misma para todo el equipo y se versiona aquí. Basta
con completarla una vez con el dominio estático del túnel.

Las configuraciones de ejecución compartidas (`.run/` para Android Studio /
IntelliJ y `.vscode/launch.json`) ya usan estos archivos.
