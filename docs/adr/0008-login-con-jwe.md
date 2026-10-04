# 0008. Credenciales cifradas con JWE en el login

**Estado:** aceptada

## Contexto
TLS protege el transporte hasta donde termina (gateway, balanceador,
proxies corporativos con inspección TLS). La contraseña no debería quedar
legible en ninguno de esos puntos ni en sus logs.

## Decisión
El cuerpo de `POST /auth/login` viaja como **JWE compacto**
(`Content-Type: application/jose`) con `alg: RSA-OAEP-256` y
`enc: A256GCM`, cifrado con la clave `use: enc` que ms-auth publica en
`/.well-known/jwks.json`. Solo ms-auth tiene la clave privada.

- Implementado con `pointycastle` (`JweEncryptor`): CEK e IV aleatorios por
  login, el encabezado protegido va como AAD de AES-GCM.
- Si el backend rotó la clave (`invalid-encrypted-payload`), la app vuelve a
  leer el JWKS y reintenta una sola vez.
- No hay *fallback* a JSON plano: evitaría un ataque de degradación.

## Alternativas
- **Solo TLS**: la contraseña queda en claro donde termina TLS.
- **Paquete `jose`**: menos control sobre el formato; con `pointycastle` el
  JWE es de unas 60 líneas y se verifica contra el backend real.

## Consecuencias
- Verificado contra ms-auth real (test de contrato) y con un test que
  descifra el JWE y detecta alteraciones (GCM).
- Si el JWKS no responde, no hay login; es el mismo servicio, así que no
  agrega un punto de falla nuevo.
