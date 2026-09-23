# Fase 0 — Setup

**Rama de trabajo:** `feature/f0-setup` (mergeada a `develop`)
**Fecha:** 2026-09

## Objetivo
Repositorio funcional, reproducible y seguro: estructura por capas, Postgres en Docker, secretos fuera del repo, health check operativo.

## Versiones fijadas
- .NET SDK 10.0.401 (pin en `global.json`, rollForward `latestFeature`)
- PostgreSQL 17 (imagen `postgres:17`)
- xUnit v3 (`xunit.v3.mtp-v2`)
- Formato de solución: `.slnx`

## Qué se construyó
- Gitflow: `main` (commit raíz vacío) ← `develop` ← `feature/f0-setup`.
- Solución `CoopSol.slnx` con 5 proyectos: `CoopSol.Domain`, `CoopSol.Application`, `CoopSol.Infrastructure`, `CoopSol.Api`, `CoopSol.Tests` — todos `net10.0`.
- `docker-compose.yml` con PostgreSQL 17, healthcheck y volumen nombrado.
- `.gitignore` que excluye secretos, artefactos de build y configuración de asistentes de IA (`CLAUDE.md`, `.claude/`, etc.) — esta exclusión vive en `develop` en adelante, **no** en `main`.
- Health check con dos endpoints: `/health/live` (proceso) y `/health/ready` (proceso + PostgreSQL), implementado con Npgsql plano (sin EF Core aún).
- User Secrets configurado para la connection string local.

## Decisiones clave y por qué
- Composition root (`Api`) referencia `Infrastructure` directamente — deuda técnica aceptada conscientemente.
- Sin EF Core todavía: se evita overengineering hasta que existan entidades reales (F2/F3).
- `TreatWarningsAsErrors=true` en `Directory.Build.props` para disciplina desde el día 1.

## Validación ejecutada
- [x] `dotnet build CoopSol.slnx` → succeeded
- [x] `docker compose up -d postgres` → healthy
- [x] `GET /health/live` → 200
- [x] `GET /health/ready` (con BD arriba) → 200
- [x] `GET /health/ready` (con BD caída) → 503, mientras `/health/live` sigue en 200
- [x] `CLAUDE.md` y `.env` confirmados como ignorados por Git
- [x] `main` sigue con 0 archivos

## Pendientes / deuda técnica
- CI/CD (F10).
- Revisar acoplamiento Api→Infrastructure si el proyecto crece mucho.

## Siguiente fase
F1 — Auth (registro/login, JWT + refresh, BCrypt, roles).