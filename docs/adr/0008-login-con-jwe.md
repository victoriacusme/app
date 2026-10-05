# 0008. Credenciales cifradas con JWE en el login

**Estado:** aceptada

**En pocas palabras:** además de HTTPS, cifro el usuario y la contraseña
dentro del propio mensaje de login, de modo que solo el servicio de
autenticación puede leerlos.

## Contexto
HTTPS (TLS) protege los datos solo hasta donde termina la conexión
cifrada: el gateway, un balanceador o un proxy corporativo que inspecciona
el tráfico. En cualquiera de esos puntos, o en sus logs, la contraseña
podría quedar legible.

## Decisión
El cuerpo de `POST /auth/login` viaja como un **JWE** (un mensaje cifrado
con formato estándar), con `Content-Type: application/jose`:

- Algoritmos: `RSA-OAEP-256` para cifrar la clave y `A256GCM` para cifrar
  el contenido.
- Uso la clave pública marcada `use: enc` que ms-auth publica en
  `/.well-known/jwks.json`. Solo ms-auth tiene la clave privada para
  descifrarlo.
- Lo implementé con `pointycastle` en `JweEncryptor`. Cada login usa una
  clave y un vector de inicialización aleatorios, y el encabezado queda
  protegido contra alteraciones.
- Si el backend rotó su clave (responde `invalid-encrypted-payload`), la
  app vuelve a leer el JWKS y reintenta una sola vez.
- **No hay plan B en texto plano:** si lo hubiera, un atacante podría
  forzar a la app a usarlo.

## Alternativas
- **Solo HTTPS:** la contraseña queda en claro donde termina la conexión
  cifrada.
- **El paquete `jose`:** me da menos control sobre el formato. Con
  `pointycastle` el JWE ocupa unas 60 líneas y lo verifiqué contra el
  backend real.

## Consecuencias
- Lo verifiqué contra ms-auth real (test de contrato) y con un test que
  descifra el JWE y detecta si alguien lo modificó.
- Si el JWKS no responde, no hay login. Como lo publica el mismo servicio
  de autenticación, no agrega un punto de falla nuevo.
