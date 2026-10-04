# 0004. Lecturas con stale-while-revalidate

**Estado:** aceptada

## Contexto
La prueba pide funcionar con conectividad limitada y caídas parciales. Una
pantalla en blanco con spinner durante 10 s de latencia no es aceptable.

## Decisión
Las lecturas devuelven un `Stream`:
1. emiten lo guardado (`fromCache: true`) al instante;
2. piden al backend y, si llega, guardan y emiten el dato nuevo;
3. si falla, conservan lo guardado con `refreshFailure` (la UI muestra
   "No pudimos actualizar · datos de hace X min"); solo sin caché hay error.

Se complementa con:
- **Retry** solo en GET (3 intentos, backoff exponencial con jitter).
- **Circuit breaker** por servicio (5 fallos → abierto 30 s → una petición
  de prueba).
- **Refresco automático** al volver la conexión.

## Alternativas
- **Network-first con caché de respaldo**: se ve vacío hasta el timeout.
- **Cache-first sin revalidar**: datos viejos sin aviso, peligroso con
  saldos.

## Consecuencias
- Con 3 s de latencia la caché se ve en menos de 500 ms
  (`test/chaos`, medido contra Toxiproxy).
- La UI siempre debe dejar claro cuándo un dato es viejo.
- El saldo mostrado puede estar desactualizado: por eso las transferencias
  las valida siempre el backend (ver ADR 0006).
