# 0010. Biometría local para volver a entrar y pantalla de privacidad

**Estado:** aceptada

## Contexto
Pedir la contraseña cada vez es incómodo; dejar la sesión abierta sin
ninguna verificación es riesgoso si alguien toma el teléfono. Además el
selector de apps no debe mostrar saldos.

## Decisión
- **Biometría (`local_auth`)**: opcional, se activa desde el perfil y solo
  en ese dispositivo (se guarda en secure storage). Activarla exige
  autenticarse primero. Con la biometría activa, la app se bloquea al
  abrirla con una sesión guardada y al volver de segundo plano tras 1 min.
  "Ingresar con mi contraseña" cierra la sesión.
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
