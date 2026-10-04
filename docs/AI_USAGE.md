# Uso de IA en el front

La app se desarrolló con **Claude Code** (asistente de programación de
Anthropic, en la terminal) como par de programación. Este documento explica
qué se le delegó, qué decidió el equipo y, sobre todo, **cómo se verificó**
lo que generó.

## Qué hizo la IA

| Fase | Trabajo asistido |
|---|---|
| 0 | Completar el `flutter create`, dependencias, lints estrictos y CI |
| 1 | Core de red (Dio + interceptores de correlation-id, auth y refresh con cola), `Result`/`Failure`, `TokenStore`, design system, login y sesión |
| 2 | Cuentas y movimientos (dominio, DTOs, repositorio, Blocs, pantallas) |
| 3 | Caché Hive cifrada, stale-while-revalidate, retry, circuit breaker, conectividad y banners |
| 4 | Transferencias con idempotencia y estado "desconocido" |
| 5 | Motor SDUI (registry, componentes, ETag, layout de respaldo), perfil y preferencias |
| 6 | Tipo de cambio (incluida la ruta del gateway) y notificaciones locales |
| 7 | Onboarding en 4 pasos |
| 8 | JWE en el login, certificate pinning SPKI, biometría y pantalla de privacidad |
| 10 | Tests E2E, capturas, ADRs y esta documentación |

En cada fase la IA **leyó primero el código del backend** (controllers,
DTOs, `GlobalExceptionHandler`, nginx) para que el front siguiera el
contrato real y no uno supuesto.

## Qué decidió el equipo
- El plan, las fases, el alcance y las prioridades.
- La estrategia de ramas y todos los commits y pushes (la IA no hizo push).
- Qué hacer ante desvíos del plan (p. ej. adelantar el onboarding).

## Cómo se verificó
Nada se dio por bueno sin una prueba que lo ejecutara:

| Verificación | Qué cubre | Cómo se corre |
|---|---|---|
| ~175 tests unitarios, de Bloc y de widgets | Lógica, estados, UI | `flutter test` |
| Golden tests | Render del home SDUI (claro/oscuro) | `flutter test test/features/experience` |
| Tests de contrato | DTOs, errores e idempotencia **contra el backend real** vía gateway | `CONTRACT_BASE_URL=... flutter test test/contract` |
| Demo de caos | Latencia, caída, circuito abierto y recuperación con Toxiproxy | `CHAOS_BASE_URL=... flutter test test/chaos` |
| E2E en emulador | Login → movimientos; login → transferencia → saldos | `flutter test integration_test -d <emulador>` |
| CI | Formato, análisis y tests en cada push | `.github/workflows/flutter-ci.yml` |

Además, se revisaron visualmente los goldens y las capturas del emulador.

## Errores de la IA que detectaron las pruebas
Lo registramos porque muestra por qué la verificación no es opcional:

- **Notificación que bloqueaba el comprobante**: el caso de uso esperaba a
  la notificación y, en Android 13+, eso incluía el diálogo de permiso. Lo
  detectó un test que simula una notificación que nunca termina.
- **Pantalla de privacidad tapando diálogos del sistema** en Android: la
  detectó el E2E de transferencia en el emulador (el toque no llegaba al
  botón).
- **Pull-to-refresh que podía quedar girando** si el refresco fallaba, y
  `Bad state: No element` si el Bloc se cerraba durante el refresco.
- **Selector de tema que no cabía** en pantallas de 360 dp (visto en las
  capturas).
- **Formato de montos** `1.250,50 $` en lugar de `$1.250,50`.
- **Prerelease de `flutter_local_notifications`** colada por un rango de
  versiones, y un conflicto de dependencias con `connectivity_plus`.
- **Configuración de nginx inválida** (regex sin comillas): la detectó
  `nginx -t` antes de recargar el gateway.

## Datos y seguridad
- A la IA no se le dieron credenciales reales: solo los usuarios de prueba
  del entorno local.
- Los tests que modifican datos (transferencias de contrato y E2E)
  devuelven el dinero al terminar; el registro solo corre con
  `CONTRACT_REGISTER=1`.

## Revisión del equipo
_(Completar: qué partes se revisaron línea por línea, qué se cambió a mano
y qué se aprendió.)_
