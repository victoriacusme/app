# ADRs del front (Nexo Bank)

Registro de decisiones de arquitectura de la app Flutter. Cada ADR explica
el contexto, la decisión, las alternativas que se descartaron y sus costos.

| # | Decisión | Estado |
|---|---|---|
| [0001](0001-hexagonal-por-feature.md) | Arquitectura hexagonal por feature en un solo paquete | Aceptada |
| [0002](0002-bloc-frente-a-riverpod.md) | Bloc para el estado, frente a Riverpod | Aceptada |
| [0003](0003-hive-ce-cifrado.md) | Caché local en Hive CE cifrado, frente a Drift | Aceptada |
| [0004](0004-stale-while-revalidate.md) | Lecturas con stale-while-revalidate | Aceptada |
| [0005](0005-sdui.md) | Home dinámico con SDUI, frente a Remote Config o Shorebird | Aceptada |
| [0006](0006-dinero-sin-conexion.md) | No encolar operaciones de dinero sin conexión; idempotencia por operación | Aceptada |
| [0007](0007-go-router-get-it.md) | go_router para navegar y get_it para inyectar dependencias | Aceptada |
| [0008](0008-login-con-jwe.md) | Credenciales cifradas con JWE en el login | Aceptada |
| [0009](0009-certificate-pinning-spki.md) | Certificate pinning por clave pública (SPKI) | Aceptada |
| [0010](0010-biometria-y-privacidad.md) | Biometría local para volver a entrar y pantalla de privacidad | Aceptada |
