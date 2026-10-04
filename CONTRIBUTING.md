# Guía de contribución

## Flujo de trabajo: Trunk Based Development

- `main` es el tronco: **siempre compila, pasa los tests y es desplegable**.
- Las ramas son de vida corta (horas, máximo 1 día): `feat/<tema>`, `fix/<tema>`, `chore/<tema>`.
- Se integra a `main` con PR pequeño + CI verde (squash o rebase merge). Se borra la rama.
- Funcionalidad incompleta se integra oculta detrás de **feature flags** (`lib/core/config/`).
- Las versiones se publican con **tags** desde `main` (`v0.1.0`, `v0.2.0`), sin ramas de release.

```bash
git switch main && git pull --rebase
git switch -c feat/accounts-cache
# commits pequeños...
git push -u origin feat/accounts-cache   # PR → CI verde → merge → borrar rama
```

## Convención de commits (Conventional Commits)

```
<tipo>(<alcance>): <descripción en imperativo>

tipos: feat, fix, test, docs, chore, ci, refactor, perf
alcances: core, auth, accounts, transfers, customer, experience, notifications
```

Ejemplos:
- `feat(accounts): add accounts repository with offline cache`
- `test(accounts): add widget tests for stale cache banner`

## Antes de abrir un PR

```bash
flutter analyze
flutter test
```

## Reglas de arquitectura

- **Hexagonal por feature**: `presentation → application → domain ← infrastructure`. El dominio es Dart puro (sin Flutter, Dio ni almacenamiento).
- Los widgets solo reaccionan a estados del Bloc; no llaman a la API directamente.
- Montos como `String` decimal desde la API, nunca `double`.
- Operaciones de dinero (POST) usan `Idempotency-Key` y **no** se reintentan automáticamente.
- Tokens solo en almacenamiento seguro; nunca registrar en logs tokens ni números de cuenta completos.
