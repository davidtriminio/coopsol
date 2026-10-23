# Fase 1c — Deuda de F1, sesión web y diseño

**Rama:** `fix/pre-f2-debt` (19 commits sobre `develop`)
**Fecha:** 2026-10

## Objetivo
Cerrar la deuda que dejó F1 antes de empezar F2, hacer que la sesión web sobreviva a las recargas con una cookie `HttpOnly` y llevar la línea gráfica de vidrio a toda la app móvil.

## Qué cambió

### Backend
| Commit | Cambio |
|---|---|
| `fix(api): return 409 on concurrent duplicate registration` | La violación de unicidad de PostgreSQL (`23505`) se traduce en el `DbContext` a una excepción de Application, que `AuthService` convierte en el conflicto de correo (409) |
| `test(api): provide web origin to the integration test host` | El host de pruebas corre en entorno `Testing`, donde no se carga `appsettings.Development.json`: se define `Cors:WebOrigin` en la factory |
| `test(api): cover concurrent registration conflict` | Unitarios con fakes, integración con 8 registros paralelos y traducción del `23505` sobre PostgreSQL |
| `feat(api): carry refresh token in HttpOnly cookie for web` | Modo cookie por `X-Auth-Mode: cookie`; `SessionResponse` sin token; CORS con credenciales y el header del modo |
| `test(api): cover cookie refresh and logout` | 12 tests de integración del modo cookie y del CORS |
| `build(api): move solution and build config into backend` | `CoopSol.slnx`, `Directory.Build.props` y `global.json` pasan a `backend/` |
| `chore(api): raise the auth rate limit in development` | 100 por minuto solo en desarrollo, porque cada recarga web hace un refresh |

### Web
| Commit | Cambio |
|---|---|
| `feat(web): restore session after page reload` | Modo cookie con credenciales; `TokenStore` sin refresh token; `restoreSession()` en un *app initializer* |
| `test(web): adapt role guard spec to the session response` | Ajuste de la spec que dejó de compilar |
| `test(web): cover session restore` | Specs de `AuthApiService`, `AuthService` y del initializer |

### Mobile
| Commit | Cambio |
|---|---|
| `fix(mobile): declare INTERNET permission in main manifest` | El release no tenía red: el permiso solo estaba en `debug` y `profile` |
| `fix(mobile): require explicit API_URL in release builds` | En release, `API_URL` es obligatoria y debe ser una URL `https` absoluta |
| `test(mobile): cover app config resolution` | 11 tests de la resolución de la URL |
| `test(mobile): reuse shared fake adapter in api service tests` | Se elimina el `FakeAdapter` duplicado |
| `feat(mobile): add design tokens, theme and bundled fonts` | Tokens, tema y fuentes TTF empaquetadas |
| `refactor(mobile): make the whole app follow the glass design` | Paleta única de vidrio, scaffolds transparentes y fondo global en `MaterialApp.builder` |
| `feat(mobile): apply glass style to login and home` | `GlassCard`, `GlassAppBar` y `BrandMark`, usados en login y home |
| `fix(mobile): lighten the dark error color for contrast` | El error del modo oscuro llegaba a 3,3:1 sobre el brillo |
| `test(mobile): cover glass theme and widgets` | 50 tests: contraste de la paleta, tema, widgets y arquitectura del fondo |

## Decisiones clave
- Refresh token web en cookie `HttpOnly`, con modo elegido por header: [ADR 0001](../adr/0001-refresh-token-en-cookie-httponly-para-web.md).
- Vidrio en toda la app con una sola paleta y tokens duplicados a mano: [ADR 0002](../adr/0002-sistema-de-diseno-de-vidrio-compartido.md).
- El backend es autocontenido en `backend/`: la solución, `Directory.Build.props` y `global.json` viven ahí. **Los comandos de .NET se ejecutan desde `backend/`**, porque `dotnet` resuelve `global.json` desde el directorio de trabajo.
- Un test de contraste con la razón WCAG sobre el color real de la tarjeta es lo que detectó el problema del error oscuro; la paleta está protegida contra regresiones.

## Configuración
| Clave | Dónde | Cambio |
|---|---|---|
| `API_URL` | `--dart-define` (mobile) | Obligatoria y `https` en release; en debug mantiene los valores por defecto |
| `RateLimiting:AuthPermitLimit` | `appsettings.Development.json` | 100 en desarrollo; producción conserva 10 |
| `Cors:WebOrigin` | `appsettings.Development.json` / `Cors__WebOrigin` | Sin cambio de valor; ahora la política permite credenciales y el header `X-Auth-Mode` |

## Paquetes
No se añadió ningún paquete NuGet, npm ni pub. Se empaquetaron fuentes como *assets* de la app móvil:

| Archivos | Origen |
|---|---|
| `sora-v17-latin-{regular,500,600}.ttf` | google-webfonts-helper (mismas versiones que la web, en TTF) |
| `ibm-plex-sans-v23-latin-{300,regular,500,600}.ttf` | idem |

Licencia de ambas: SIL Open Font License 1.1. Origen y licencia en `mobile/assets/fonts/README.md`.

## Validación ejecutada
- [x] `dotnet test CoopSol.slnx` desde `backend/` con Docker: **57 tests** (31 unitarios y 26 de integración)
- [x] `ng test` en la web: **30 tests**
- [x] `flutter test`: **145 tests** y `flutter analyze` sin avisos
- [x] Flujo del modo cookie con PowerShell: `Set-Cookie` con los atributos esperados, cuerpo sin `refreshToken`, rotación con cookie distinta, 401 al reutilizar la cookie vieja, logout 204, y el modo body de mobile sin cambios
- [x] Navegador: login, recarga en `/profile` con la sesión restaurada, `document.cookie` vacío, cierre de sesión y recarga que vuelve al login
- [x] APK de release compilado con `API_URL` y permiso `INTERNET` comprobado con `aapt dump permissions`
- [x] Fuentes comprobadas con su hash SHA-256 y con todos los caracteres del español
- [x] App móvil en el emulador: login y home con el estilo de vidrio, en modo claro y oscuro

## Deuda técnica
- **La web sigue sin el estilo de vidrio** (login en teal e interior plano). Es una tarea aparte y debe usar la tabla del ADR 0002.
- `login.html` de la web tiene `class="brand-mark-"` (clase inexistente), un `]` suelto y comentarios de plantilla; el rediseño lo reescribe.
- Carrera de refresh entre pestañas o peticiones concurrentes: concurrencia optimista en F4.
- El móvil muestra el login si no hay red al abrir aunque conserve el token: se resuelve con offline-read en F3.
- Despliegue: la cookie exige web y API del mismo *site*; hay que decidir entre subdominios o un rewrite de Vercel (F10).
- `POST /api/auth/register` revela con un 409 qué correos existen (enumeración de usuarios): endurecimiento en F10.
- `BackdropFilter` es costoso en gama baja: en listas largas habrá que usar tarjetas sin desenfoque.
- Las etiquetas de los campos del modo oscuro llegan a 4,1:1 sobre la zona más brillante del brillo.
- `CorsExtensions.cs` solo permite `GET` y `POST`: F2 deberá ampliarlo para `PUT`, `PATCH` y `DELETE`.
- Sin CI todavía (F10) y `Api` referencia `Infrastructure` directamente (deuda aceptada).