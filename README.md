# CoopSol

Plataforma de gestión interna para una cooperativa de ahorro y crédito hondureña.
No es banca real, no mueve dinero real, no da asesoría financiera. Proyecto de aprendizaje intensivo.

## Stack
- Backend: .NET 10 (SDK 10.0.401), ASP.NET Core minimal APIs, EF Core 10 (desde F2/F3), PostgreSQL 17.
- Web: Angular 20+ (standalone, signals, zoneless).
- Mobile: Flutter/Dart.
- Infra: Docker Compose.

## Arquitectura
Clean Architecture "lite" por capas: `Domain` → `Application` → `Infrastructure` → `Api`.

## Cómo levantar el entorno local

1. Copia el archivo de entorno y define tu contraseña de desarrollo:
   ```pwsh
    Copy-Item .env.example .env
   ```

2. Levanta PostgreSQL:
```pwsh
   docker compose up -d postgres
```

3. Configura la connection string en User Secrets (una sola vez):
   ```pwsh
   dotnet user-secrets init --project backend/CoopSol.Api
   dotnet user-secrets set "ConnectionStrings:Default" "Host=localhost;Port=5432;Database=coopsol_dev;Username=coopsol;Password=<tu-password>" --project backend/CoopSol.Api
   ```

4. Corre la API:
```pwsh
dotnet run --project backend/CoopSol.Api 
```   

5. Verifica:
- `GET /health/live` → proceso vivo.
- `GET /health/ready` → proceso vivo y BD alcanzable.
## Tests

```pwsh
dotnet test CoopSol.slnx
```

## Documentación por fase
Ver [`docs/fases/`](docs/fases/) para el reporte de cada fase (qué se construyó, decisiones, validación).