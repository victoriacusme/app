# 0010. Biometría local para volver a entrar y pantalla de privacidad

**Estado:** aceptada

## Contexto
Pedir la contraseña cada vez es incómodo; dejar la sesión abierta sin
ninguna verificación es riesgoso si alguien toma el teléfono. Además el
selector de apps no debe mostrar saldos.

## Decisión
- **Biometría (`local_auth`)**: opcional, se activa desde el perfil y solo
  en ese dispositivo (se guarda en secure storage). Activarla exige
  autenticarse primero.
- **El login ofrece dos formas de entrar**: usuario y contraseña, y el botón
  "Ingresar con huella o rostro". El botón aparece cuando hay una sesión
  guardada en el dispositivo y la biometría está activada.
- Con la biometría activada, la sesión queda guardada pero **bloqueada**
  (la app muestra el login) al abrir la app, al volver de segundo plano tras
  1 min y al tocar "Cerrar sesión". Así se puede volver a entrar con huella.
- "¿No eres tú? Usar otra cuenta" cierra la sesión del todo y la revoca en
  el backend. Sin biometría activada, "Cerrar sesión" también la cierra del
  todo.
- La biometría **desbloquea la sesión local**; no reemplaza la
  autenticación con el backend (los tokens siguen siendo los de ms-auth).
- **Privacidad en el selector de apps**: en Android release se usa
  `FLAG_SECURE` (tampoco se pueden hacer capturas); en iOS la app se tapa al
  pasar a `inactive`. En Android no se tapa en `inactive`, porque eso
  también ocurre con diálogos del sistema (permisos) y taparía la app
  detrás del diálogo.

## Alternativas
- **Guardar la contraseña y enviarla tras la biometría**: nunca se guarda la
  contraseña.
- **FLAG_SECURE también en debug**: impediría grabar la demo.

## Consecuencias
- Un login con contraseña nunca queda bloqueado inmediatamente después.
- Las pruebas usan un `BiometricAuth` falso; en el emulador la biometría se
  puede simular desde los controles extendidos.
