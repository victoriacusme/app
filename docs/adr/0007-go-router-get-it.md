# 0007. go_router para navegar y get_it para inyectar dependencias

**Estado:** aceptada

## Contexto
La navegación depende de la sesión (login, bloqueo con biometría) y debe
abrir deep links desde el home SDUI y desde las notificaciones.

## Decisión
- **go_router** con `redirect` según `SessionCubit` y `AppLockCubit`
  (`/splash`, `/login`, `/register`, `/locked`, `/home`, `/accounts/:id`,
  `/transfer`, `/profile`). Los enlaces `app://...` se traducen a rutas en
  `DeepLinks`.
- **get_it** como contenedor: singletons para infraestructura (Dio,
  repositorios, caché) y factories para Blocs, que se crean por ruta con
  `BlocProvider`.

## Alternativas
- **Navigator 2.0 a mano**: mucho código para redirecciones y deep links.
- **auto_route**: tipado fuerte, pero con generación de código.
- **Riverpod / injectable** para DI: más magia o generación de código; get_it
  es explícito y suficiente.

## Consecuencias
- Las reglas de acceso están en un solo lugar (`_redirect`).
- get_it es un service locator: los widgets no lo usan directamente, solo el
  router y `main`, para que la UI siga siendo testeable con mocks.
