# All In Fit Backend

All In Fit is a .NET 9 backend for a health and fitness SaaS platform. The solution uses Clean Architecture with CQRS, DDD, SQL Server, Redis, RabbitMQ, SignalR, Hangfire, and Serilog.

## Solution Layout

- `src/AllInFit.Domain` domain entities, value objects, events, and specifications.
- `src/AllInFit.Application` CQRS commands, queries, validators, behaviors, and port interfaces.
- `src/AllInFit.Infrastructure` external adapters for auth, caching, messaging, payments, storage, notifications, maps, and jobs.
- `src/AllInFit.Persistence` EF Core context, repositories, unit of work, interceptors, migrations, and seed data.
- `src/AllInFit.Presentation` ASP.NET Core Web API, middleware, filters, Swagger, versioning, and hubs.
- `src/AllInFit.Shared` shared contracts, constants, result types, and security helpers.
- `tests/AllInFit.Tests` unit, integration, API, security, and performance smoke coverage.

## Run Locally

```powershell
dotnet restore AllInFit.slnx
dotnet build AllInFit.slnx
dotnet test tests/AllInFit.Tests/AllInFit.Tests.csproj
dotnet run --project src/AllInFit.Presentation/AllInFit.Presentation.csproj --launch-profile http
```

## Docker

```powershell
docker compose up --build
```

The API is exposed through NGINX on port `80` and directly on `8080`.

## Documentation

- [Architecture](docs/architecture.md)
- [ERD](docs/erd.md)
- [Data Dictionary](docs/data-dictionary.md)
- [Sequence Diagrams](docs/sequence-diagrams.md)
- [Class Diagrams](docs/class-diagrams.md)
- [API Documentation](docs/api-documentation.md)
- [Deployment Guide](DEPLOYMENT.md)
- Postman collection: `docs/AllInFit.postman_collection.json`