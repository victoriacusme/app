# 0004. Lecturas con stale-while-revalidate

**Estado:** aceptada

**En pocas palabras:** cuando el usuario abre una pantalla, le muestro al
instante lo último que guardé y, mientras tanto, pido los datos nuevos al
backend. Si no llegan, sigue viendo lo guardado con un aviso de que puede
estar desactualizado.

## Contexto
La app tiene que funcionar bien con internet lento o con algún servicio
caído. Una pantalla en blanco con un indicador de carga girando durante
10 segundos no es aceptable.

## Decisión
Las lecturas devuelven un `Stream` (una secuencia de resultados) en tres
pasos:

1. Emiten al instante lo guardado (`fromCache: true`).
2. Piden los datos al backend; si llegan, los guardan y los emiten.
3. Si fallan, conservan lo guardado y marcan `refreshFailure`. La pantalla
   muestra "No pudimos actualizar · datos de hace X min". Solo si no hay
   nada guardado se muestra un error.

Lo complemento con:

- **Reintentos** solo en lecturas (GET): 3 intentos, cada vez esperando un
  poco más y con una pequeña variación aleatoria para no saturar al
  backend.
- **Circuit breaker** por servicio: si un servicio falla 5 veces seguidas,
  dejo de llamarlo durante 30 segundos y luego pruebo con una sola
  petición.
- **Refresco automático** cuando vuelve la conexión.

## Alternativas
- **Primero la red, la caché solo si falla:** la pantalla se ve vacía
  hasta que vence el tiempo de espera.
- **Solo la caché, sin volver a pedir:** muestra datos viejos sin avisar,
  y eso es peligroso con saldos.

## Consecuencias
- Con 3 segundos de latencia, los datos guardados aparecen en menos de
  medio segundo. Lo medí con Toxiproxy en `test/chaos`.
- La pantalla siempre tiene que dejar claro cuándo un dato es viejo.
- El saldo que ve el usuario puede no estar al día; por eso las
  transferencias las valida siempre el backend (ver ADR 0006).
