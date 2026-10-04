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

Usuarios de prueba: `ana` (joven), `carlos` (premium) y `lucia`
(emprendedora), con contraseña `Nexo2026*`. Cada uno ve un home distinto.
También puedes crear una cuenta desde "¿No tienes cuenta? Crea una".

## Calidad

```bash
flutter analyze
flutter test

# Contrato contra el backend real vía gateway (opcional; mueve $1,00
# entre cuentas de `carlos` y lo devuelve)
CONTRACT_BASE_URL=http://localhost:8080 flutter test test/contract
# ...incluyendo el registro (crea un usuario nuevo en cada corrida)
CONTRACT_BASE_URL=http://localhost:8080 CONTRACT_REGISTER=1 flutter test test/contract

# Demo de resiliencia con Toxiproxy: latencia → caída → circuito abierto →
# recuperación (restaura Toxiproxy al terminar)
CHAOS_BASE_URL=http://localhost:8080 flutter test test/chaos

# Regenerar los golden tests del home SDUI
flutter test --update-goldens test/features/experience/sdui_golden_test.dart
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
    ├── auth/           login · onboarding (registro en 4 pasos)
    ├── accounts/       cuentas · movimientos
    ├── transfers/      formulario · confirmación · comprobante
    ├── customer/       perfil · preferencias (edición optimista)
    ├── experience/     home SDUI · registry · componentes
    ├── fx/             tipo de cambio (servicio externo)
    └── notifications/  aviso local tras transferir · deep links
```

## Home dinámico (SDUI)

`GET /experience/home` devuelve la lista de componentes del home según el
segmento, la hora y las preferencias. La app recorre `components` en orden y
el `ComponentRegistry` traduce cada `type` a un widget:

| type | Qué muestra | Estado propio |
|---|---|---|
| `greeting` | Saludo | — |
| `accounts_summary` | Cuentas y saldo total | `AccountsBloc` |
| `quick_actions` | Accesos por deep link | — |
| `savings_goal` | Progreso de una meta | `AccountsBloc` |
| `promo_banner` | Promoción con deep link | — |
| `fx_rates` | Tipo de cambio | `FxCubit` |

- Un `type` desconocido o con props inválidas **se ignora**: el backend puede
  publicar componentes nuevos sin romper versiones viejas de la app.
- El último layout se guarda en caché y se revalida con `ETag` (304).
- Si ms-customer no responde y no hay caché, se usa
  `assets/experience/home_fallback.json`.
- Cada sección se degrada sola: si cae el tipo de cambio se oculta; si cae
  ms-accounts, las cuentas muestran su caché.

Deep links soportados: `app://transfers`, `app://accounts/{id}`,
`app://profile`, `app://home`. Los demás muestran "disponible pronto".

## Notificaciones

Tras una transferencia exitosa se muestra una notificación local (si el
cliente las tiene activadas en su perfil). Tocarla abre la cuenta de origen,
también con la app cerrada. El contenido se oculta en la pantalla de
bloqueo. Push remoto (FCM) requiere un proyecto de Firebase y no está
configurado.

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
