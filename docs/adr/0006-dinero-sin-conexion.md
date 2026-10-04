# 0006. No encolar operaciones de dinero sin conexión; idempotencia por operación

**Estado:** aceptada

## Contexto
Una transferencia puede quedar en duda: el backend la ejecutó pero la
respuesta no llegó (timeout, corte de red, 5xx del gateway). Reintentar a
ciegas puede duplicarla; encolarla sin conexión puede ejecutarla horas
después con saldos que el usuario ya no recuerda.

## Decisión
- **No se encola**: sin conexión el botón "Confirmar" se deshabilita y se
  explica por qué.
- **No se reintenta automáticamente**: el `RetryInterceptor` solo actúa en
  GET.
- La `Idempotency-Key` se genera **una vez por operación confirmada** (al
  pasar a la pantalla de confirmación), no por petición HTTP. Si el usuario
  edita los datos, se descarta y la siguiente operación usa otra.
- Si el resultado es desconocido (timeout, sin red, 5xx), la app muestra
  "No pudimos confirmar el resultado" y ofrece **"Verificar estado"**, que
  reenvía el mismo POST con la misma clave: el backend devuelve el
  resultado original (`Idempotent-Replayed: true`) sin ejecutarla de nuevo.
- Un circuito abierto sí es un rechazo: la petición nunca salió.

### Diferencia con el plan original
El plan proponía consultar `GET /transfers/{id}` en el estado desconocido.
Sin respuesta la app no conoce ese `id`; el backend documenta reenviar la
misma solicitud con la misma clave, y eso es lo que se implementó.

## Consecuencias
- Nunca hay transferencias duplicadas (probado contra el backend real:
  misma clave → misma transferencia; misma clave con otro monto → 409).
- El usuario debe esperar a tener conexión para transferir.
