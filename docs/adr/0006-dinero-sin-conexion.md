# 0006. No encolar operaciones de dinero sin conexión; idempotencia por operación

**Estado:** aceptada

**En pocas palabras:** una transferencia nunca se envía dos veces. Sin
internet no se puede transferir, nada se guarda para enviarlo después, y si
la respuesta se pierde, la app pregunta por el resultado en lugar de
repetir la operación.

## Contexto
Una transferencia puede quedar en duda: el backend la ejecutó, pero la
respuesta no llegó al teléfono (se acabó el tiempo de espera, se cortó la
red o el gateway respondió con un error 5xx). Si reintento a ciegas, puedo
duplicarla. Si la guardo para enviarla cuando vuelva la conexión, puede
ejecutarse horas después, con saldos que el usuario ya no tiene presentes.

## Decisión
- **No se encola:** sin conexión, el botón "Confirmar" se deshabilita y la
  app explica por qué.
- **No se reintenta automáticamente:** el `RetryInterceptor` solo actúa en
  lecturas (GET).
- **Una clave de idempotencia por operación:** genero la
  `Idempotency-Key` una sola vez, al pasar a la pantalla de confirmación,
  no en cada petición HTTP. Con esa clave el backend reconoce que es la
  misma operación. Si el usuario vuelve y cambia los datos, descarto la
  clave y la siguiente operación usa otra.
- **Resultado desconocido:** si no hubo respuesta, la app muestra "No
  pudimos confirmar el resultado" y ofrece **"Verificar estado"**. Ese
  botón reenvía el mismo POST con la misma clave, y el backend devuelve el
  resultado original (`Idempotent-Replayed: true`) sin ejecutarla de
  nuevo.
- **Circuito abierto:** cuenta como rechazo, porque la petición nunca salió
  del teléfono.

### Por qué no consulto `GET /transfers/{id}`
Al principio pensé consultar la transferencia por su `id` cuando el
resultado es desconocido. Pero si no llegó la respuesta, la app no conoce
ese `id`. El backend documenta que hay que reenviar la misma solicitud con
la misma clave, y eso es lo que implementé.

## Consecuencias
- No hay transferencias duplicadas. Lo probé contra el backend real: la
  misma clave devuelve la misma transferencia, y la misma clave con otro
  monto responde 409 (conflicto).
- El usuario tiene que esperar a tener conexión para transferir.
