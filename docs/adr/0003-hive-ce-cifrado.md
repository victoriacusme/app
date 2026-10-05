# 0003. Caché local en Hive CE cifrado, frente a Drift

**Estado:** aceptada

**En pocas palabras:** guardo en el teléfono la última respuesta del
backend (saldos, movimientos, home) para mostrarla sin conexión, y la
guardo cifrada porque son datos bancarios.

## Contexto
Quiero que la app siga mostrando saldos y movimientos aunque no haya
internet o el backend esté caído. Pero son datos sensibles: no pueden
quedar legibles en el almacenamiento del teléfono.

## Decisión
Uso Hive CE con `HiveAesCipher` (cifrado AES-256):

- La clave de cifrado se genera la primera vez y se guarda en el
  almacenamiento seguro del sistema (Keychain en iOS, Keystore en Android)
  con `flutter_secure_storage`.
- Guardo el JSON de cada respuesta junto con su fecha.
- Al cerrar sesión, o si la sesión expira, borro toda la caché.

Tengo un test que revisa el archivo en disco y confirma que los montos no
aparecen en texto plano.

## Alternativas
- **Drift (SQLite):** consultas y migraciones con tipos, pero necesita
  generación de código y SQLCipher para cifrar. Yo no necesito hacer
  consultas, solo guardar la última respuesta.
- **`shared_preferences`:** no cifra.

## Consecuencias
- Es simple y no necesita generación de código.
- No hay consultas: la caché es "la última respuesta por clave"
  (`accounts:list`, `accounts:movements:{id}`, `experience:home`…).
- Si cambia el formato de una respuesta y una caché vieja ya no se puede
  leer, se descarta en lugar de romper la app.
