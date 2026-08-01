$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

# 1) Cache options
$cacheOptions = @'
namespace AllInFit.Infrastructure.Caching;

public sealed class CacheOptions
{
    public const string SectionName = "Cache";

    public bool Enabled { get; set; }
    public string? RedisConnectionString { get; set; }
    public int DefaultExpirationMinutes { get; set; } = 30;
}
'@
[System.IO.File]::WriteAllText("$base\Caching\CacheOptions.cs", $cacheOptions, [System.Text.Encoding]::UTF8)
Write-Host "Created CacheOptions.cs"

# 2) Memory cache service
$memoryService = @'
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace AllInFit.Infrastructure.Caching;

public sealed class MemoryCacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly JsonSerializerOptions _jsonOptions;

    public MemoryCacheService(IMemoryCache cache)
    {
        _cache = cache;
        _jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    }

    public Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class
    {
        if (_cache.TryGetValue(key, out string? json) && json is not null)
        {
            var value = JsonSerializer.Deserialize<T>(json, _jsonOptions);
            return Task.FromResult(value);
        }
        return Task.FromResult<T?>(null);
    }

    public Task SetAsync<T>(string key, T value, TimeSpan? expiration = null, CancellationToken cancellationToken = default) where T : class
    {
        var options = new MemoryCacheEntryOptions();
        if (expiration.HasValue)
            options.AbsoluteExpirationRelativeToNow = expiration;

        var json = JsonSerializer.Serialize(value, _jsonOptions);
        _cache.Set(key, json, options);
        return Task.CompletedTask;
    }

    public Task RemoveAsync(string key, CancellationToken cancellationToken = default)
    {
        _cache.Remove(key);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(_cache.TryGetValue(key, out _));
    }
}
'@
[System.IO.File]::WriteAllText("$base\Caching\MemoryCacheService.cs", $memoryService, [System.Text.Encoding]::UTF8)
Write-Host "Created MemoryCacheService.cs"

# 3) Rewrite DependencyInjection with conditional Redis
$di = @'
using AllInFit.Infrastructure.Auth;
using AllInFit.Infrastructure.Caching;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureLayer(this IServiceCollection services, IConfiguration configuration)
    {
        // Options
        services.Configure<CacheOptions>(configuration.GetSection(CacheOptions.SectionName));
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));

        // Auth
        services.AddScoped<IJwtProvider, JwtProvider>();

        // Caching
        services.AddMemoryCache();

        using (var provider = services.BuildServiceProvider())
        {
            var cacheOptions = provider.GetRequiredService<IOptions<CacheOptions>>().Value;

            if (cacheOptions.Enabled)
            {
                var redisConnection = cacheOptions.RedisConnectionString
                    ?? configuration.GetConnectionString("Redis")
                    ?? "localhost:6379";

                services.AddStackExchangeRedisCache(options =>
                {
                    options.Configuration = redisConnection;
                    options.InstanceName = "AllInFit:";
                });
                services.AddScoped<ICacheService, RedisCacheService>();

                services.AddHealthChecks()
                    .AddRedis(redisConnection, name: "redis", tags: ["cache", "redis"]);
            }
            else
            {
                services.AddScoped<ICacheService, MemoryCacheService>();
            }
        }

        return services;
    }
}
'@
[System.IO.File]::WriteAllText("$base\DependencyInjection.cs", $di, [System.Text.Encoding]::UTF8)
Write-Host "Rewrote DependencyInjection.cs"

Write-Host "Cache fix complete"
