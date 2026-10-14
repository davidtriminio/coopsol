# Fase 1a — Auth (Backend)

**Rama:** `feature/f1-auth-backend`
**Fecha:** 2026-09

## Objetivo
Registro y login con JWT + refresh tokens, contraseñas con BCrypt y autorización por rol.
Sin ASP.NET Core Identity completo.

## Versiones resueltas
| Paquete | Versión |
|---|---|
| Microsoft.EntityFrameworkCore / .Relational / .Design | 10.0.12 |
| Npgsql.EntityFrameworkCore.PostgreSQL | 10.0.3 |
| BCrypt.Net-Next | 4.2.0 |
| Microsoft.IdentityModel.JsonWebTokens | 8.23.0 |
| Microsoft.AspNetCore.Authentication.JwtBearer | 10.0.12 |
| Microsoft.Extensions.DependencyInjection.Abstractions | 10.0.12 |
| Microsoft.AspNetCore.Mvc.Testing | 10.0.12 |
| Testcontainers.PostgreSql | 4.15.0 |

## Endpoints
| Método | Ruta | Acceso |
|---|---|---|
| POST | /api/auth/register | Público (crea solo Socio) |
| POST | /api/auth/login | Público |
| POST | /api/auth/refresh | Público (rota el refresh token) |
| POST | /api/auth/logout | Público (revoca el refresh token) |
| GET | /api/auth/me | JWT |
| POST | /api/admin/users | JWT + rol Admin |

Errores: RFC 9457 (ProblemDetails). 400 validación, 401 credenciales/token, 403 rol, 409 email duplicado, 429 rate limit.

## Decisiones clave
- Access token JWT (HS256) de 15 min; refresh token opaco de 7 días guardado como hash SHA-256.
- Rotación en cada refresh; si se reutiliza un refresh revocado se revocan todas las sesiones del usuario.
- BCrypt work factor 12 con pre-hash SHA-384 ("enhanced") para evitar el truncamiento a 72 bytes.
- Login ecualiza tiempos (verifica contra un hash falso si el usuario no existe) y devuelve el mismo error.
- El registro público ignora cualquier rol; el staff lo crea un Admin. El primer Admin se siembra
  desde `Seed:AdminEmail` / `Seed:AdminPassword` (idempotente).
- La app no arranca si `Jwt:Secret` falta o tiene menos de 32 bytes (`ValidateOnStart`).
- EF Core entra en esta fase (antes previsto para F2/F3): usuarios y refresh tokens necesitan persistencia.
- Migraciones automáticas solo en Development; en producción son un paso de despliegue.

## Configuración
| Clave | Dónde |
|---|---|
| ConnectionStrings:Default | User Secrets / `ConnectionStrings__Default` |
| Jwt:Secret | User Secrets / `Jwt__Secret` (nunca en el repo) |
| Seed:AdminEmail, Seed:AdminPassword | User Secrets / `Seed__AdminEmail`, `Seed__AdminPassword` |
| Jwt:Issuer, Jwt:Audience, Jwt:AccessTokenMinutes, Jwt:RefreshTokenDays | appsettings.json |
| RateLimiting:AuthPermitLimit | appsettings.json (10 por minuto por IP) |

Nota: `.env.example` lista `JWT_SECRET`; la API lee `Jwt:Secret` (o `Jwt__Secret` como variable de entorno).

## Validación ejecutada
- [x] `dotnet build CoopSol.slnx` sin warnings (TreatWarningsAsErrors)
- [x] 29 tests unitarios en verde
- [x] 12 tests de integración (Testcontainers) en verde — marcar tras correrlos con Docker
- [x] Prueba manual con PowerShell (register → login → me → refresh → reuso → 401)
- [x] Verificar hashes en BD (`$2a$12$`/`$2b$12$`, TokenHash de 64 caracteres)

## Deuda técnica
- Carrera en refresh concurrente (se resuelve con concurrencia optimista en F4).
- Carrera en registro devuelve 500 en vez de 409 (mapear 23505 de Postgres).
- Rate limit por IP requiere ForwardedHeaders tras un proxy.
- Sin lockout, cambio de contraseña ni desactivación de usuarios.
- Columnas en PascalCase (sin convención snake_case).