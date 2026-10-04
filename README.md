# Nexo Bank: app móvil (Flutter)

App de banca personas. Arquitectura hexagonal por feature
(`domain` · `application` · `infrastructure` · `presentation`) con Bloc.

## Requisitos

- Flutter 3.47.6 (stable), Dart 3.13
- Backend levantado (`app-backend`, `docker compose up`)

## Ejecutar

```bash
flutter pub get

# Emulador Android contra el gateway (puerto 8080)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Mientras no exista el gateway, directo contra ms-auth
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081

# Simulador iOS
flutter run --dart-define=API_BASE_URL=http://localhost:8081
```

En debug se permite HTTP solo hacia `10.0.2.2`, `localhost` y `127.0.0.1`.
Los builds de release exigen HTTPS.

Usuarios de prueba: `ana`, `carlos`, `lucia` (contraseña `Nexo2026*`).

## Calidad

```bash
flutter analyze
flutter test

# Contrato contra ms-auth real (opcional)
CONTRACT_BASE_URL=http://localhost:8081 flutter test test/contract
```

## Estructura

```
lib/
├── app/            app · router · di · session_cubit
├── core/           config · network (Dio + interceptores) · security · result
├── design_system/  tema · tokens · widgets
└── features/
    └── auth/       login
```
