# 0010. Biometría local para volver a entrar y pantalla de privacidad

**Estado:** aceptada

**En pocas palabras:** el cliente puede volver a entrar con su huella o su
rostro en lugar de escribir la contraseña, y la app oculta su contenido
cuando aparece en la lista de apps abiertas.

## Contexto
Pedir la contraseña cada vez es incómodo, pero dejar la sesión abierta sin
ninguna verificación es riesgoso si alguien toma el teléfono. Además, la
vista de apps abiertas del sistema no debe mostrar saldos.

## Decisión
**Biometría (`local_auth`):**

- Es opcional: el cliente la activa desde su perfil, y vale solo para ese
  teléfono (queda guardado en el almacenamiento seguro). Para activarla
  tiene que autenticarse primero.
- El login ofrece dos formas de entrar: usuario y contraseña, y el botón
  "Ingresar con huella o rostro". El botón aparece cuando hay una sesión
  guardada en el teléfono y la biometría está activada.
- Con la biometría activada, la sesión queda guardada pero **bloqueada**
  (se muestra el login) al abrir la app, al volver a ella después de 1
  minuto en segundo plano y al tocar "Cerrar sesión". Así puede volver a
  entrar con su huella.
- "¿No eres tú? Usar otra cuenta" cierra la sesión por completo y la
  revoca en el backend. Sin biometría, "Cerrar sesión" también la cierra
  por completo.
- La biometría **solo desbloquea la sesión guardada en el teléfono**; no
  reemplaza la autenticación con el backend. Los tokens siguen siendo los
  que emite ms-auth.

**Privacidad en la vista de apps abiertas:**

- En Android (versión release) uso `FLAG_SECURE`, que además impide tomar
  capturas de pantalla.
- En iOS tapo la app cuando pasa a estado `inactive`.
- En Android no la tapo en `inactive`, porque ese estado también ocurre
  cuando aparece un diálogo del sistema (por ejemplo, un permiso), y la app
  quedaría tapada detrás del diálogo.

## Alternativas
- **Guardar la contraseña y enviarla después de la huella:** descartado;
  la contraseña nunca se guarda.
- **`FLAG_SECURE` también en debug:** me impediría tomar capturas y grabar
  la pantalla mientras desarrollo.

## Consecuencias
- Un login con contraseña nunca queda bloqueado justo después de entrar.
- Las pruebas usan un `BiometricAuth` falso. En el emulador, la huella se
  puede simular desde los controles extendidos.
