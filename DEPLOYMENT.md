# Deployment Guide

## Prerequisites

- .NET 9 SDK
- SQL Server 2022 or compatible
- Redis 7+
- RabbitMQ 3+
- Docker and Docker Compose for containerized deployment

## Configuration

Set the following environment variables in production:

- `ConnectionStrings__DefaultConnection`
- `ConnectionStrings__Redis`
- `ConnectionStrings__RabbitMQ`
- `Jwt__Issuer`
- `Jwt__Audience`
- `Jwt__SecretKey`
- `Cache__Enabled`
- `EventBus__Enabled`
- `Hangfire__Enabled`
- `RateLimiting__Enabled`

## Database Strategy

- Apply migrations from the `src/AllInFit.Persistence` assembly.
- Keep backups before deploying schema changes.
- Use the `Testing` environment only for automated verification; production should remain on `Production`.

## Docker Deployment

```powershell
docker compose up --build -d
```

The stack includes SQL Server, Redis, RabbitMQ, the API, and NGINX.

## Operational Checks

- `GET /health` for readiness and database connectivity.
- `GET /swagger/v1/swagger.json` for API contract validation in non-production environments.
- Review Serilog outputs in `logs/` and any container logs.

## Rollback

- Roll back the application container image.
- Restore the previous database backup if a schema migration is involved.
- Re-run health checks after rollback.