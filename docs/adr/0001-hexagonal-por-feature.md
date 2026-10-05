# 0001. Arquitectura hexagonal por feature en un solo paquete

**Estado:** aceptada

**En pocas palabras:** organicé el código por funcionalidad (cuentas,
transferencias, login…) y, dentro de cada una, separé la lógica del negocio
de los detalles técnicos (red, base de datos, pantallas). Así puedo probar
la lógica sola y cambiar una pieza sin romper las demás.

## Contexto
La app crece por funcionalidades de negocio: login, cuentas,
transferencias, perfil del cliente, home dinámico, tipo de cambio y
notificaciones. Necesitaba dos cosas:

- Probar la lógica sin levantar Flutter ni depender de la red.
- Poder cambiar un detalle técnico (el cliente HTTP, la caché, el servicio
  de notificaciones) sin tocar el resto de la app.

## Decisión
Cada feature se divide en cuatro capas:

| Capa | Qué contiene | Ejemplo en cuentas |
|---|---|---|
| `domain` | Las reglas y los datos del negocio, en Dart puro. También los **puertos**: interfaces que dicen *qué* necesito sin decir *cómo* se hace. | `Account`, `AccountRepository` |
| `application` | Los **casos de uso**: cada acción concreta que hace el usuario. | `WatchAccounts`, `GetMovements` |
| `infrastructure` | Los **adaptadores**: el *cómo*. Implementan los puertos con Dio, Hive o un plugin. | `AccountRepositoryImpl` |
| `presentation` | El estado de la pantalla (Bloc) y los widgets. | `AccountsBloc`, `MovementsPage` |

Lo que usan todas las features vive aparte: `core/` (red, seguridad,
caché, conectividad, dinero) y `design_system/` (tema y widgets comunes).

La regla principal es que **las dependencias apuntan hacia el dominio**:

```text
presentation → application → domain ← infrastructure
```

El dominio no conoce a Flutter, a Dio ni a la base de datos; solo usa
tipos básicos de `core`, como `Money` y `Result`. Quien conecta cada
puerto con su adaptador al arrancar la app es `app/di.dart`, con `get_it`.

Todo vive en **un solo paquete** (`lib/features/*`), y todas las features
(`auth`, `accounts`, `transfers`, `customer`, `experience`, `fx`,
`notifications`) siguen la misma forma:

```text
lib/
├── app/            arranque: dependencias, rutas, sesión, ajustes
├── core/           piezas comunes (red, seguridad, caché, dinero…)
├── design_system/  tema y widgets reutilizables
└── features/<feature>/
    ├── domain/          entidades + puertos      → usa solo core
    ├── application/     casos de uso             → usa domain
    ├── infrastructure/  adaptadores              → usa domain y core
    └── presentation/    Bloc + widgets           → usa application, domain y design_system
```

## Alternativas
- **Capas globales** (`lib/data`, `lib/domain`, `lib/ui`): mezcla todas
  las features, y un cambio en cuentas termina tocando carpetas de todo el
  proyecto.
- **Un paquete por feature (con melos):** aísla mejor, pero suma
  configuración, versiones y tiempo de compilación que no compensan en un
  equipo pequeño.

## Consecuencias
- Pruebo la lógica con implementaciones falsas de los puertos: más de 220
  tests unitarios y de widgets corren en segundos.
- Tengo que cuidar que una feature no use la `infrastructure` de otra. Hoy
  solo se comparten entidades del dominio (por ejemplo, `transfers` usa
  `Account`).
- Si el equipo crece, cada carpeta de `features/` se puede convertir en un
  paquete propio sin reescribirla.
