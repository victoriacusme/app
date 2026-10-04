# 0003. Caché local en Hive CE cifrado, frente a Drift

**Estado:** aceptada

## Contexto
La app debe seguir mostrando saldos y movimientos sin conexión o con el
backend caído. Esos datos son sensibles y no pueden quedar en claro en el
dispositivo.

## Decisión
Hive CE con `HiveAesCipher` (AES-256). La clave se genera la primera vez y
se guarda en Keychain/Keystore (`flutter_secure_storage`). Se guarda el
JSON de las respuestas con su fecha. Al cerrar o expirar la sesión se borra
toda la caché.

Un test verifica que el archivo en disco no contiene los montos en claro.

## Alternativas
- **Drift (SQLite)**: consultas y migraciones tipadas, pero necesita
  generación de código y SQLCipher para cifrar; no necesitamos consultas,
  solo guardar la última respuesta.
- **shared_preferences**: sin cifrado.

## Consecuencias
- Simple y sin generación de código.
- No hay consultas: la caché es "última respuesta por clave"
  (`accounts:list`, `accounts:movements:{id}`, `experience:home`...).
- Si cambia el formato de una respuesta, una caché vieja ilegible se
  descarta en lugar de romper la app.
