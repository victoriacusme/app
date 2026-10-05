# 0009. Certificate pinning por clave pública (SPKI)

**Estado:** aceptada

**En pocas palabras:** en producción, la app solo habla con un servidor si
su certificado tiene una clave pública que yo conozco de antemano. Así
nadie puede hacerse pasar por el backend, aunque tenga un certificado
"válido".

## Contexto
Si una autoridad certificadora es comprometida, o si alguien instala un
certificado en el teléfono (un MDM de empresa o un malware), podría
interceptar el tráfico de la app aunque use HTTPS.

## Decisión
En producción, Dio solo acepta servidores cuyo certificado tenga una clave
pública cuyo hash SHA-256 esté en mi lista de **pines**. La lista llega por
`--dart-define` en `PIN_SHA256`, separada por comas, con el mismo formato
que `sha256/<base64>` de OkHttp o TrustKit.

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.nexo.ec \
  --dart-define=PIN_SHA256=<pin actual>,<pin de respaldo>
```

Sin `PIN_SHA256` (en desarrollo, contra el backend local por HTTP) el
pinning queda apagado.

## Alternativas
- **Fijar el certificado completo:** cada renovación del certificado
  obligaría a publicar la app. Fijando la clave, puedo renovar el
  certificado conservando la misma clave.
- **Fijar la autoridad certificadora:** es más flexible, pero confía en
  todo lo que esa autoridad emita.

## Consecuencias
- Siempre hay que publicar **al menos un pin de respaldo**: una clave ya
  generada y guardada fuera de línea. Sin él, un cambio de clave de
  emergencia dejaría a todos los clientes sin servicio.
- Lo probé con un certificado real: el hash coincide con el que calcula
  `openssl`, y una conexión TLS real se acepta con el pin correcto y se
  rechaza con otro.
