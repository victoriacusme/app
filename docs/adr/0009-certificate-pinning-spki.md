# 0009. Certificate pinning por clave pública (SPKI)

**Estado:** aceptada

## Contexto
Un certificado emitido por una CA comprometida o instalado en el
dispositivo (MDM, malware) permitiría interceptar el tráfico.

## Decisión
En producción, Dio solo acepta servidores cuyo certificado tenga una clave
pública con hash SHA-256 en la lista de pines (`PIN_SHA256`, por
`--dart-define`, separados por coma). Es el mismo formato que
`sha256/<base64>` de OkHttp o TrustKit.

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.nexo.ec \
  --dart-define=PIN_SHA256=<pin actual>,<pin de respaldo>
```

Sin `PIN_SHA256` (desarrollo contra HTTP local) el pinning queda apagado.

## Alternativas
- **Pinear el certificado completo**: cada renovación obliga a publicar la
  app. Pinear la clave permite renovar el certificado conservando la clave.
- **Pinear la CA**: más flexible, pero confía en todo lo que emita esa CA.

## Consecuencias
- Siempre se debe publicar **al menos un pin de respaldo** (una clave ya
  generada y guardada fuera de línea); si no, una rotación de emergencia
  deja a todos los clientes sin servicio.
- Probado con un certificado real: el hash coincide con `openssl` y una
  conexión TLS real se acepta con el pin correcto y se rechaza con otro.
