# Fase 1b — Auth (Web y Mobile)

**Rama:** `feature/f1-auth-backend` (contiene backend, web y mobile de F1)
**Fecha:** 2026-10

## Objetivo
Consumir la API de autenticación de F1a desde las dos aplicaciones cliente:
una SPA Angular para el staff y una app Flutter para el socio. Ambas renuevan la
sesión de forma transparente y reaccionan cuando la sesión se pierde.

## Versiones resueltas
| Pieza | Versión |
|---|---|
| Angular (core, router, forms, cli) | 22.2.0 |
| TypeScript | 6.0.3 |
| Vitest / jsdom (tests web) | 5.0.2 / 30.1.1 |
| Flutter / Dart | 3.47.6 / 3.13.x |
| dio | 5.11.1 |
| flutter_secure_storage | 11.2.0 |
| flutter_lints | 6.0.0 |

## Web (staff)
| Ruta | Acceso |
|---|---|
| `/login` | Público |
| `/profile` | Autenticado |
| `/admin/users/new` | Autenticado + rol Admin |

- Token store con signals; el access y el refresh token viven solo en memoria.
- Interceptor HTTP: agrega el Bearer y, ante un 401, renueva una sola vez y reintenta.
- `RefreshCoordinator` comparte una única renovación en vuelo entre peticiones concurrentes.
- Guards funcionales: `authGuard` y `roleGuard('Admin')`.
- Pantalla para que un Admin cree usuarios de staff.

## Mobile (socio)
| Estado de sesión | Pantalla |
|---|---|
| `restoring` | indicador de carga |
| `unauthenticated` | login |
| `authenticated` | inicio (provisional) |

- `TokenStore` observable (`ChangeNotifier`): access token en memoria, refresh token en `flutter_secure_storage`.
- Dos clientes `Dio`: uno sin interceptor para renovar y otro con `AuthInterceptor` para el resto.
- `RefreshCoordinator` de un solo vuelo. Solo borra la sesión si el servidor rechaza el token, no ante fallos de red.
- `SessionController` deriva el estado del store; el portero (`SessionGate`) no navega, reacciona.
- La app solo admite rol Socio: otro rol se rechaza **antes** de guardar la sesión y se revoca el refresh token emitido.

## Decisiones clave
- Los dos clientes comparten el diseño de renovación: una renovación en vuelo, un reintento por petición, rutas de login y refresh exentas.
- El estado de sesión móvil se calcula desde el store en vez de duplicarse, para que lo que haga el interceptor se refleje en pantalla.
- La restricción de rol en el móvil es de experiencia de uso. El control real lo hace la API por endpoint.
- Sin `go_router`, `riverpod`, `get_it` ni `json_serializable`: con tres pantallas y una fuente de estado no resuelven un problema real.

## Configuración
| Clave | Dónde |
|---|---|
| `apiUrl` (web) | `web/src/environments/environment*.ts` |
| `API_URL` (mobile) | `--dart-define=API_URL=...`; por defecto `http://10.0.2.2:5143` en Android y `http://localhost:5143` en el resto |

Ningún secreto vive en los clientes: solo la URL de la API.

## Paquetes del móvil (por proyecto)
| Paquete | Uso |
|---|---|
| dio | cliente HTTP e interceptores |
| flutter_secure_storage | persistencia cifrada del refresh token |
| cupertino_icons | plantilla de Flutter, sin uso propio |
| flutter_lints | reglas de análisis (herramienta) |

## Validación ejecutada
- [x] `dotnet test CoopSol.slnx` con Docker encendido: 41 tests (29 unitarios y 12 de integración)
- [x] Tests web (Vitest) y `ng build` en verde
- [x] `flutter test`: 84 tests en verde y `flutter analyze` sin avisos
- [x] Flujo manual de la API: registro, duplicado (409), claves de 7 y 129 caracteres (400), `role` ignorado en el registro, login (200/401), `/me` sin token (401), endpoint de admin con token de socio (403), rotación y reutilización de refresh token (401), límite de peticiones (429)
- [x] App móvil en dispositivo: login, reapertura con sesión, cierre de sesión, rol distinto de Socio rechazado, errores de red y de límite

## Deuda técnica
- Falta el permiso `INTERNET` en el manifiesto de release de Android (`mobile/android/app/src/main/AndroidManifest.xml`); solo está en `debug` y `profile`. Un APK de release no tendría red.
- En release hay que pasar `API_URL` con HTTPS; el valor por defecto es `http://`.
- El web pierde la sesión al recargar la página (tokens solo en memoria; no hay restauración de sesión).
- El móvil muestra el login si no hay red al abrir, aunque conserve el refresh token. Se resuelve con offline-read.
- `describeLoginError` convierte cualquier excepción inesperada en "no se pudo conectar".
- `restore()` se lanza sin `await` en `main.dart`; un fallo del almacenamiento seguro quedaría sin capturar.
- Pantalla de inicio del móvil provisional; no hay registro de socios desde la app.
- Un `FakeAdapter` está copiado en `auth_api_service_test.dart`; el resto usa `test/support/fake_http.dart`.
- `dotnet test CoopSol.slnx` con Docker apagado reporta "cero tests" en vez de los unitarios.
