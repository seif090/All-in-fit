using AllInFit.Persistence.Data;
using AllInFit.Persistence.Interceptors;
using AllInFit.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Persistence;

public static class DependencyInjection
{
    public static IServiceCollection AddPersistenceLayer(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
        var databaseProvider = configuration["Database:Provider"] ?? "SqlServer";

        services.AddScoped<AuditInterceptor>();
        services.AddScoped<DomainEventInterceptor>();

        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            var auditInterceptor = sp.GetRequiredService<AuditInterceptor>();
            var domainEventInterceptor = sp.GetRequiredService<DomainEventInterceptor>();

            if (databaseProvider.Equals("Sqlite", StringComparison.OrdinalIgnoreCase))
            {
                options.UseSqlite(connectionString);
            }
            else
            {
                options.UseSqlServer(connectionString, sqlOptions =>
                {
                    sqlOptions.CommandTimeout(120);
                    sqlOptions.EnableRetryOnFailure(3);
                    sqlOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
                });
            }

            options
            .AddInterceptors(auditInterceptor, domainEventInterceptor);
        });

        // Register concrete repositories
        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        // Register as Application.Ports for clean architecture
        services.AddScoped(typeof(AllInFit.Application.Ports.IGenericRepository<>), typeof(GenericRepository<>));
        // Register UnitOfWork as both interfaces
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<AllInFit.Application.Ports.IUnitOfWork>(sp => sp.GetRequiredService<IUnitOfWork>());

        return services;
    }
}