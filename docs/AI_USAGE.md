# Uso de IA en la app

Desarrollé la app con **Claude Code** (el asistente de programación de
Anthropic, en la terminal) como compañero de programación. En este
documento explico qué le pedí, qué decidí yo y, sobre todo, **cómo verifiqué**
lo que generó.

## En qué me ayudó

| Fase | Trabajo con asistencia |
|---|---|
| 0 | Completar el `flutter create`, las dependencias, las reglas de análisis estrictas y el CI |
| 1 | Base de red (Dio con interceptores de correlation-id, autenticación y renovación de tokens), manejo de errores (`Result`/`Failure`), `TokenStore`, design system, login y sesión |
| 2 | Cuentas y movimientos (dominio, DTOs, repositorio, Blocs y pantallas) |
| 3 | Caché cifrada con Hive, stale-while-revalidate, reintentos, circuit breaker, conectividad y avisos |
| 4 | Transferencias con idempotencia y el estado "resultado desconocido" |
| 5 | Home dinámico SDUI (registro de componentes, ETag, layout de respaldo), perfil y preferencias |
| 6 | Tipo de cambio (incluida su ruta en el gateway) y notificaciones |
| 7 | Crear cuenta en 4 pasos |
| 8 | JWE en el login, certificate pinning, biometría y pantalla de privacidad |
| 10 | Pruebas E2E, capturas, ADRs y documentación |
| — | Traducción completa a español e inglés, idioma según el teléfono, rediseño del login y conexión automática al backend desde cualquier dispositivo |

En cada fase le pedí que **leyera primero el código del backend**
(controllers, DTOs, `GlobalExceptionHandler`, nginx), para que la app
siguiera el contrato real y no uno supuesto.

## Qué decidí yo

- El plan, las fases, el alcance y las prioridades.
- El diseño de la experiencia (por ejemplo, el login con dos formas de
  entrar, que el idioma siga al teléfono y que cada campo se valide al
  salir de él).
- La estrategia de ramas, y todos los commits y pushes: la IA nunca hizo
  push.
- Qué hacer cuando algo se desviaba del plan (por ejemplo, adelantar el
  registro de cuentas).

## Cómo lo verifiqué

No di nada por bueno sin una prueba que lo ejecutara:

| Verificación | Qué cubre | Cómo se ejecuta |
|---|---|---|
| Más de 220 tests unitarios, de Bloc y de widgets | Lógica, estados e interfaz | `flutter test` |
| Golden tests | Cómo se dibuja el home (tema claro y oscuro) | `flutter test test/features/experience` |
| Tests de contrato | DTOs, errores e idempotencia **contra el backend real**, a través del gateway | `CONTRACT_BASE_URL=... flutter test test/contract` |
| Pruebas de caos | Latencia, caída, circuito abierto y recuperación con Toxiproxy | `CHAOS_BASE_URL=... flutter test test/chaos` |
| E2E en emulador y teléfono | Login → movimientos; transferencia → saldos; crear cuenta; promociones | `flutter test integration_test/<archivo> -d <dispositivo>` |
| CI | Formato, análisis y tests en cada push | `.github/workflows/flutter-ci.yml` |

Además, revisé a ojo los goldens y las capturas del emulador, y probé los
flujos a mano en un teléfono físico.

## Errores de la IA que encontraron las pruebas

Los dejo registrados porque muestran por qué la verificación no es
opcional:

- **La notificación bloqueaba el comprobante:** el caso de uso esperaba a
  la notificación y, en Android 13 o superior, eso incluía el diálogo de
  permiso. Lo detectó un test que simula una notificación que nunca
  termina.
- **La pantalla de privacidad tapaba los diálogos del sistema** en
  Android. Lo detectó el E2E de transferencia: el toque no llegaba al
  botón.
- **El gesto de refrescar podía quedarse girando** si el refresco fallaba,
  y aparecía `Bad state: No element` si el Bloc se cerraba a mitad del
  refresco.
- **El selector de tema no cabía** en pantallas de 360 dp. Lo vi en las
  capturas.
- **Formato de montos:** mostraba `1.250,50 $` en lugar de `$1.250,50`.
- **Versiones de dependencias:** un rango dejó pasar una versión
  preliminar de `flutter_local_notifications`, y había un conflicto con
  `connectivity_plus`.
- **Configuración de nginx inválida** (una expresión regular sin
  comillas): la detectó `nginx -t` antes de recargar el gateway.
- **Diagnóstico equivocado:** atribuyó un fallo de E2E al límite de
  peticiones del gateway. Al revisar los logs del backend vi que no había
  ningún 429; el problema real era una recarga del home sin sesión
  después de cerrar sesión.
- **Rama equivocada:** en una ocasión creó una rama nueva en lugar de
  seguir en la que estaba trabajando, y tuve que pedirle que moviera los
  cambios.

## Datos y seguridad

- No le di credenciales reales: solo los usuarios de prueba del entorno
  local.
- Los tests que modifican datos (contrato y E2E de transferencia)
  devuelven el dinero al terminar. El de registro solo corre con
  `CONTRACT_REGISTER=1`.

## Mi revisión

_(Pendiente de completar: qué partes revisé línea por línea, qué cambié a
mano y qué aprendí.)_
