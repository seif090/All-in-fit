using AllInFit.Infrastructure.Auth;
using AllInFit.Infrastructure.Caching;
using AllInFit.Infrastructure.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureLayer(this IServiceCollection services, IConfiguration configuration)
    {
        // Auth
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.AddScoped<IJwtProvider, JwtProvider>();

        // Caching
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = configuration.GetConnectionString("Redis") ?? "localhost:6379";
            options.InstanceName = "AllInFit:";
        });
        services.AddScoped<ICacheService, RedisCacheService>();

        // Memory cache fallback
        services.AddMemoryCache();

        // Health checks
services.AddHealthChecks()
            .AddRedis(configuration.GetConnectionString("Redis") ?? "localhost:6379", name: "redis");

        return services;
    }
}