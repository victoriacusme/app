# Nexo Bank: app móvil (Flutter)

App de banca personas. Arquitectura hexagonal por feature
(`domain` · `application` · `infrastructure` · `presentation`) con Bloc.

## Requisitos

- Flutter 3.47.6 (stable), Dart 3.13
- Backend levantado (`app-backend`, `docker compose up`)

## Ejecutar

```bash
flutter pub get

# Emulador Android contra el gateway (valor por defecto)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Simulador iOS
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

En debug se permite HTTP solo hacia `10.0.2.2`, `localhost` y `127.0.0.1`.
Los builds de release exigen HTTPS.

Usuarios de prueba: `ana`, `carlos`, `lucia` (contraseña `Nexo2026*`).

## Calidad

```bash
flutter analyze
flutter test

# Contrato contra el backend real vía gateway (opcional; mueve $1,00
# entre cuentas de `carlos` y lo devuelve)
CONTRACT_BASE_URL=http://localhost:8080 flutter test test/contract
```

## Flujo de trabajo

Ver [CONTRIBUTING.md](CONTRIBUTING.md) (Trunk Based Development y Conventional Commits).

## Estructura

```
lib/
├── app/            app · router · di · session_cubit
├── core/           config · network (Dio + interceptores) · security · storage
│                   (Hive cifrado) · connectivity · money · result
├── design_system/  tema · tokens · widgets (skeleton, banners, estados)
└── features/
    ├── auth/       login
    ├── accounts/   home de cuentas · movimientos
    └── transfers/  formulario · confirmación · comprobante
```

## Resiliencia

- **Stale-while-revalidate:** cuentas y movimientos se muestran primero
  desde la caché cifrada (Hive CE + AES, clave en Keychain/Keystore) y
  luego se actualizan. Si el backend falla, los datos guardados siguen
  visibles con el banner "No pudimos actualizar".
- **Retry:** solo GET, 3 intentos con backoff exponencial y jitter.
- **Circuit breaker:** por servicio; tras 5 fallos corta 30 s y luego
  prueba con una petición.
- **Sin conexión:** banner global y refresco automático al volver la red.
- **Transferencias:** nunca se reintentan ni se encolan. La
  `Idempotency-Key` se crea al confirmar; si no hay respuesta, "Verificar
  estado" reenvía la misma clave y el backend devuelve el resultado
  original sin duplicar el movimiento.
- Al cerrar sesión se borran tokens y caché.
