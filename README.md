# Nexo Bank — App móvil

App Flutter de banca digital para personas. Arquitectura hexagonal por feature.
Consume los microservicios del repositorio **Backend** (ms-auth, ms-customer, ms-accounts).

> En construcción. Ver [CONTRIBUTING.md](CONTRIBUTING.md) para el flujo Trunk Based Development.

## Estructura

```
lib/
├── app/            # shell: rutas, DI, tema
├── core/           # network, security, storage, config, observability, result
├── design_system/
└── features/       # auth, accounts, transfers, customer, experience, notifications
    └── <feature>/
        ├── domain/          entidades y puertos (Dart puro)
        ├── application/     casos de uso
        ├── infrastructure/  adaptadores: API (Dio), caché local
        └── presentation/    Bloc, páginas y widgets
test/               # unitarias y de widgets
integration_test/   # E2E
```

## Requisitos

- Flutter (stable) con Dart 3.8+
- Backend levantado (ver repositorio Backend)

## Primeros pasos

```bash
# Solo la primera vez: genera las carpetas de plataforma
flutter create . --org ec.nexo --project-name nexo_bank --platforms=android,ios

flutter pub get
flutter run
flutter test
```
