# ADR 0001 — Refresh token en cookie HttpOnly para la web

- **Estado:** aceptada
- **Fecha:** 2026-10-17
- **Contexto de fase:** deuda de F1 (rama `fix/pre-f2-debt`)

## Contexto

La web de staff guardaba el access token y el refresh token solo en memoria. Eso tenía un costo visible: **recargar la página cerraba la sesión**.

Había que restaurar la sesión al recargar sin exponer el refresh token. El refresh token dura 7 días, así que quien lo robe tiene una sesión larga. Mobile es un cliente distinto: guarda el token en `flutter_secure_storage` y lo envía en el cuerpo de la petición; no tiene el modelo de cookies de un navegador.

## Decisión

El refresh token de la web viaja en una cookie con estos atributos:

| Atributo | Valor | Motivo |
|---|---|---|
| Nombre | `coopsol_refresh` | |
| `HttpOnly` | sí | JavaScript no puede leerla, así que un XSS no puede robarla |
| `Secure` | siempre | seguro por defecto; `localhost` cuenta como contexto seguro en Chrome y Edge |
| `SameSite` | `Strict` | el navegador no la envía en peticiones iniciadas desde otro sitio |
| `Path` | `/api/auth` | solo la reciben los endpoints de auth |
| `Expires` | ahora + `Jwt:RefreshTokenDays` | misma vida que el token guardado en BD |

El modo se elige por petición con el header `X-Auth-Mode: cookie`:

| Modo | Login y refresh responden | Refresh y logout leen el token de |
|---|---|---|
| Sin header (mobile) | `AuthResponse` con `refreshToken` | el cuerpo JSON |
| `X-Auth-Mode: cookie` (web) | `SessionResponse`, **sin** `refreshToken`, más `Set-Cookie` | la cookie; el cuerpo ni se lee |

El access token sigue en memoria. Al arrancar, la web llama a `POST /api/auth/refresh` desde un *app initializer* y no deja que la navegación empiece hasta tener respuesta. Si el servidor la rechaza, el usuario ve el login.

**Defensa contra CSRF, en capas:** `SameSite=Strict`; un header personalizado que obliga a un preflight CORS; CORS con un único origen exacto y credenciales; y la cookie se borra cuando el servidor la rechaza.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Refresh token en `sessionStorage` o `localStorage` | Es legible por cualquier XSS. Es más simple, pero es justo lo que se quiere evitar |
| Cookie para todos los clientes | Mobile no es un navegador; forzarle cookies complica su cliente sin beneficio |
| Endpoints distintos para web (`/api/auth/web/...`) | Duplica rutas y lógica; un header basta |
| Un BFF o proxy que guarde la sesión | Sobre-ingeniería para el tamaño del proyecto |

## Consecuencias

**Positivas**
- La sesión web sobrevive a recargas y el refresh token no es accesible desde JavaScript.
- Mobile no cambia: sin el header, el comportamiento es el anterior.

**Costos y limitaciones**
- Dos caminos de código en los endpoints de auth y un DTO más (`SessionResponse`).
- **Despliegue (decidir en F10).** `SameSite=Strict` exige que web y API sean del mismo *site*. Con la web en Vercel y la API en otro servidor hay dos caminos:
    - **A.** Dominio propio con subdominios (`app.` y `api.` del mismo dominio registrable).
    - **B.** Un `rewrite` en Vercel que reenvíe `/api/*` a la API: el navegador ve un solo origen, `apiUrl` queda vacío y no hace falta CORS en producción.
- Safari no trata `http://localhost` como contexto seguro: para desarrollar usa Chrome o Edge.
- Cada recarga de la web hace una llamada a refresh y cuenta contra el límite de los endpoints públicos (10 por minuto en producción; 100 en desarrollo).
- La cookie se comparte entre pestañas: dos pestañas que refresquen a la vez con la misma cookie pueden disparar la detección de reutilización. Es la carrera de refresh ya anotada para F4.
- Si el logout falla (por ejemplo, sin red), la sesión local se limpia pero la cookie sigue viva hasta que expire o se rechace.

## Verificación

- 12 tests de integración sobre PostgreSQL real: atributos de la cookie, rotación, reutilización con borrado de cookie, logout, modo body sin cambios, y preflight desde el origen web y desde uno ajeno.
- Specs web del servicio de auth y del initializer.
- Prueba manual en navegador: login, recarga en `/profile` con sesión restaurada, `document.cookie` vacío, cierre de sesión y recarga que devuelve al login.