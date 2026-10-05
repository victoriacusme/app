# Cómo contribuir

Esta guía explica cómo trabajo en el proyecto: cómo organizo las ramas,
cómo escribo los commits y qué reglas de arquitectura sigo. Si vas a
aportar código, sigue los mismos pasos.

## Ramas: Trunk Based Development

La idea es tener una sola rama principal que siempre funciona, e integrar
cambios pequeños con frecuencia.

- `main` es el tronco: **siempre compila, pasa los tests y se puede
  desplegar**.
- Las ramas duran poco (horas, máximo un día) y se nombran según el tipo
  de cambio: `feat/<tema>`, `fix/<tema>`, `chore/<tema>`.
- Cada rama entra a `main` con un PR pequeño y el CI en verde (con squash
  o rebase). Después se borra.
- Si algo no está terminado pero conviene integrarlo, se oculta detrás de
  una bandera (*feature flag*) hasta que esté listo.
- Las versiones se publican con **tags** desde `main` (`v0.1.0`,
  `v0.2.0`), sin ramas de release.

```bash
git switch main && git pull --rebase
git switch -c feat/cache-cuentas
# commits pequeños...
git push -u origin feat/cache-cuentas   # PR → CI verde → merge → borrar la rama
```

## Mensajes de commit: Conventional Commits

Cada commit empieza con su tipo, para que el historial se entienda de un
vistazo:

```
<tipo>(<alcance opcional>): <qué cambia>

tipos:    feat, fix, test, docs, chore, ci, refactor, perf
alcances: core, auth, accounts, transfers, customer, experience, notifications
```

Ejemplos:

- `feat(accounts): caché cifrada de cuentas sin conexión`
- `fix(auth): validar cada campo al salir de él en crear cuenta`
- `test(accounts): banner de datos desactualizados`
- `docs: diagrama de la arquitectura`

## Antes de abrir un PR

Ejecuta lo mismo que revisa el CI:

```bash
dart format lib test
flutter analyze
flutter test
```

## Reglas de arquitectura

Están explicadas en detalle en los [ADRs](docs/adr/README.md). En resumen:

- **Hexagonal por feature:** `presentation → application → domain ←
  infrastructure`. El dominio es Dart puro: no usa Flutter, Dio ni el
  almacenamiento ([ADR 0001](docs/adr/0001-hexagonal-por-feature.md)).
- **Los widgets no llaman a la API:** solo muestran el estado de su Bloc y
  le envían eventos.
- **Los montos nunca son `double`:** llegan como texto decimal y se
  manejan en centavos con `Money`, para no perder precisión.
- **Las operaciones de dinero no se repiten solas:** los POST llevan
  `Idempotency-Key` y no se reintentan automáticamente
  ([ADR 0006](docs/adr/0006-dinero-sin-conexion.md)).
- **Los datos sensibles no se registran:** los tokens van solo al
  almacenamiento seguro, y nunca se escriben en logs tokens ni números de
  cuenta completos.
- **Todo texto visible se traduce:** se agrega en `lib/l10n/app_es.arb` y
  `app_en.arb` y se usa con `context.l10n.<clave>`.
