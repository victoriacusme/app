# 0007. go_router para navegar y get_it para inyectar dependencias

**Estado:** aceptada

**En pocas palabras:** go_router decide a qué pantalla va el usuario según
si inició sesión o no, y get_it crea y entrega las piezas que cada pantalla
necesita.

## Contexto
La navegación depende de la sesión: si no hay sesión va al login, y si la
sesión está bloqueada pide huella. Además, la app tiene que abrir enlaces
internos (deep links) que llegan desde el home dinámico y desde las
notificaciones.

## Decisión
- **go_router**, con una función `redirect` que mira `SessionCubit` y
  `AppLockCubit` y manda a cada usuario a la pantalla que le corresponde.
  Rutas: `/splash`, `/login`, `/register`, `/home`, `/accounts/:id`,
  `/transfer`, `/transfers/:id` y `/profile`.
- Los enlaces `app://...` se traducen a rutas en `DeepLinks`.
- **get_it** como contenedor de dependencias: una sola instancia
  compartida para la infraestructura (Dio, repositorios, caché) y una
  instancia nueva de cada Bloc por pantalla, que se entrega con
  `BlocProvider`.

## Alternativas
- **Navigator 2.0 a mano:** demasiado código para redirecciones y deep
  links.
- **auto_route:** rutas con tipos, pero necesita generación de código.
- **Riverpod o injectable para las dependencias:** más magia o generación
  de código; get_it es explícito y suficiente.

## Consecuencias
- Las reglas de acceso a cada pantalla están en un solo lugar
  (`_redirect`).
- Solo el router y `main` usan get_it; los widgets reciben lo que
  necesitan por `BlocProvider`. Así la interfaz se prueba fácilmente con
  mocks.
