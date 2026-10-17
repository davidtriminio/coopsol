# CoopSol

Plataforma de gestión interna para una cooperativa de ahorro y crédito hondureña.
No es banca real, no mueve dinero real, no da asesoría financiera. Proyecto de aprendizaje intensivo.

## Stack

- Backend: .NET 10 (SDK 10.0.401), ASP.NET Core minimal APIs, EF Core 10, PostgreSQL 17.
- Web (staff): Angular 22 (standalone, signals, zoneless), TypeScript 6, pnpm, tests con Vitest.
- Mobile (socio): Flutter 3.47 / Dart 3.13, `dio`, `flutter_secure_storage`.
- Infra: Docker Compose.

## Arquitectura

Clean Architecture "lite" por capas: `Domain` → `Application` → `Infrastructure` → `Api`.
Los clientes (`web/` y `mobile/`) consumen la API REST y no guardan secretos.

## Cómo levantar el entorno local

### 1. Base de datos y API

1. Copia el archivo de entorno y define tu contraseña de desarrollo:
   ```pwsh
   Copy-Item .env.example .env
   ```

2. Levanta PostgreSQL:
   ```pwsh
   docker compose up -d postgres
   ```

3. Configura los secretos en User Secrets (una sola vez):
   ```pwsh
   cd backend
   dotnet user-secrets init --project CoopSol.Api
   dotnet user-secrets set "ConnectionStrings:Default"
   "Host=localhost;Port=5432;Database=coopsol_dev;Username=coopsol;Password=<tu-password>" --project CoopSol.Api
   $secret = [Convert]::ToBase64String ([System.Security.Cryptography.RandomNumberGenerator]::GetBytes (64))
   dotnet user-secrets set "Jwt:Secret" $secret --project CoopSol.Api
   dotnet user-secrets set "Seed:AdminEmail" "admin@coopsol.local" --project CoopSol.Api
   dotnet user-secrets set "Seed:AdminPassword" "<elige-una-clave-de-12+-caracteres>" --project CoopSol.Api
   ```

4. Corre la API (escucha en `http://localhost:5143`):
   ```pwsh
   cd backend
   dotnet run --project CoopSol.Api
   ```

5. Verifica:
    - `GET /health/live` → proceso vivo.
    - `GET /health/ready` → proceso vivo y BD alcanzable.

### 2. Web (staff)

Requiere la API corriendo.

```pwsh
cd web
pnpm install
pnpm start
```

Abre `http://localhost:4200`. Entra con el Admin sembrado en el paso 3.
Desde `/admin/users/new` un Admin crea usuarios de staff.

### 3. Mobile (socio)

Requiere la API corriendo y un emulador Android o un dispositivo conectado.

```pwsh
cd mobile
flutter pub get
flutter run
```

En Android, el emulador llega a la API en `http://10.0.2.2:5143`. Para otra URL:

```pwsh
flutter run --dart-define=API_URL=http://192.168.1.10:5143
```

La app solo admite el rol Socio. Crea uno con el registro público de la API:

```pwsh
$body = @{ email = 'socio@coopsol.local'; password = '<clave-de-8+-caracteres>'; fullName = 'Socio de Prueba' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri http://localhost:5143/api/auth/register -ContentType 'application/json' -Body $body
```

## Endpoints de autenticación

| Método | Ruta               | Acceso                            |
|--------|--------------------|-----------------------------------|
| POST   | /api/auth/register | Público (crea Socio)              |
| POST   | /api/auth/login    | Público                           |
| POST   | /api/auth/refresh  | Público (rota el refresh token)   |
| POST   | /api/auth/logout   | Público (revoca el refresh token) |
| GET    | /api/auth/me       | JWT                               |
| POST   | /api/admin/users   | JWT + rol Admin                   |

Los endpoints públicos de auth tienen un límite de 10 peticiones por minuto.

## Tests


Backend (los de integración usan Testcontainers y requieren Docker Desktop encendido):
Cada bloque parte de la raíz del repo. Los comandos de .NET se ejecutan desde `backend/`, porque ahí viven `global.json` (SDK y runner de tests) y `Directory.Build.props`.

```pwsh
cd backend
dotnet test CoopSol.slnx
```

Web:

```pwsh
cd web
pnpm exec ng test --watch=false
```

Mobile:

```pwsh
cd mobile
flutter test
flutter analyze
```

## Documentación por fase

Ver [`docs/fases/`](docs/fases/) para el reporte de cada fase (qué se construyó, decisiones, validación).
