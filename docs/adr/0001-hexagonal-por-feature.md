# 0001. Arquitectura hexagonal por feature en un solo paquete

**Estado:** aceptada

## Contexto
La app crece por funcionalidades de negocio (auth, cuentas, transferencias,
cliente, experiencia, tipo de cambio, notificaciones). Necesitamos poder
probar la lógica sin Flutter ni red, y cambiar un adaptador (HTTP, caché,
notificaciones) sin tocar el resto.

## Decisión
Cada feature tiene `domain` (entidades y puertos, Dart puro),
`application` (casos de uso), `infrastructure` (adaptadores: Dio, Hive,
plugins) y `presentation` (Bloc y widgets). Lo transversal vive en `core/`
(red, seguridad, caché, conectividad, dinero) y `design_system/`.
Las dependencias apuntan hacia el dominio: `presentation → application →
domain ← infrastructure`.

Todo vive en **un solo paquete** (`lib/features/*`).

## Alternativas
- **Capas globales** (`lib/data`, `lib/domain`, `lib/ui`): mezcla features y
  hace que un cambio de cuentas toque carpetas de todo el proyecto.
- **Un paquete por feature (melos)**: aísla mejor, pero suma configuración,
  versiones y tiempo de build que no compensan con un equipo pequeño.

## Consecuencias
- La lógica se prueba con fakes de los puertos (más de 170 tests unitarios
  y de widgets corren en segundos).
- Hay que vigilar que una feature no importe la `infrastructure` de otra;
  hoy solo se comparten entidades de dominio (p. ej. `transfers` usa
  `Account`).
- Si el equipo crece, cada carpeta de `features/` se puede extraer a un
  paquete sin reescribirla.
