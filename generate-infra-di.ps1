$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

# ===== InMemoryEventBus fallback (used when RabbitMQ is disabled) =====
$inMemory = @'
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Messaging;

/// <summary>
/// In-process event bus used when RabbitMQ is disabled.
/// Handlers are dispatched synchronously via the service provider.
/// </summary>
public sealed class InMemoryEventBus : IEventBus
{
    private readonly IServiceProvider _services;
    private readonly ILogger<InMemoryEventBus> _logger;

    public InMemoryEventBus(IServiceProvider services, ILogger<InMemoryEventBus> logger)
    {
        _services = services;
        _logger = logger;
    }

    public async Task PublishAsync<T>(T integrationEvent, CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
    {
        ArgumentNullException.ThrowIfNull(integrationEvent);

        using var scope = _services.CreateScope();
        var handlers = scope.ServiceProvider.GetServices<IIntegrationEventHandler<T>>().ToArray();

        if (handlers.Length == 0)
        {
            _logger.LogDebug("No handlers registered for {EventType}", typeof(T).Name);
            return;
        }

        _logger.LogInformation("Dispatching {EventType} to {HandlerCount} handler(s)", typeof(T).Name, handlers.Length);
        foreach (var handler in handlers)
        {
            await handler.HandleAsync(integrationEvent, cancellationToken);
        }
    }

    public Task SubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        _logger.LogDebug("In-memory bus: subscription for {EventType} is implicit", typeof(T).Name);
        return Task.CompletedTask;
    }

    public Task UnsubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        _logger.LogDebug("In-memory bus: unsubscription for {EventType} is implicit", typeof(T).Name);
        return Task.CompletedTask;
    }
}
'@
[System.IO.File]::WriteAllText("$base\Messaging\InMemoryEventBus.cs", $inMemory, [System.Text.Encoding]::UTF8)
Write-Host "Created InMemoryEventBus.cs"

$content = @'
using AllInFit.Infrastructure.Auth;
using AllInFit.Infrastructure.Caching;
using AllInFit.Infrastructure.Maps;
using AllInFit.Infrastructure.Messaging;
using AllInFit.Infrastructure.Notifications;
using AllInFit.Infrastructure.Payments;
using AllInFit.Infrastructure.Storage;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureLayer(this IServiceCollection services, IConfiguration configuration)
    {
        // ========== Options ==========
        services.Configure<CacheOptions>(configuration.GetSection(CacheOptions.SectionName));
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.SectionName));
        services.Configure<PaymentOptions>(configuration.GetSection(PaymentOptions.SectionName));
        services.Configure<MapServiceOptions>(configuration.GetSection(MapServiceOptions.SectionName));
        services.Configure<EventBusOptions>(configuration.GetSection(EventBusOptions.SectionName));
        services.Configure<EmailOptions>(configuration.GetSection(EmailOptions.SectionName));
        services.Configure<SmsOptions>(configuration.GetSection(SmsOptions.SectionName));
        services.Configure<PushOptions>(configuration.GetSection(PushOptions.SectionName));

        // Named HTTP clients for external adapters
        services.AddHttpClient("MapService");
        services.AddHttpClient("Paymob");
        services.AddHttpClient("Fawry");

        // ========== Auth ==========
        services.AddScoped<IJwtProvider, JwtProvider>();

        // ========== Caching ==========
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

        // ========== Event Bus (RabbitMQ) ==========
        var eventBusOptions = configuration.GetSection(EventBusOptions.SectionName).Get<EventBusOptions>() ?? new EventBusOptions();
        if (eventBusOptions.Enabled)
        {
            services.AddSingleton<IEventBus, RabbitMqEventBus>();
        }
        else
        {
            // In-process event bus fallback keeps the system runnable without RabbitMQ.
            services.AddSingleton<IEventBus, InMemoryEventBus>();
        }

        // ========== Notifications ==========
        services.AddScoped<IEmailSender, SmtpEmailSender>();
        services.AddScoped<ISmsSender, TwilioSmsSender>();
        services.AddScoped<IPushNotificationService, FirebasePushNotificationService>();

        // ========== File Storage ==========
        var storageOptions = configuration.GetSection(StorageOptions.SectionName).Get<StorageOptions>() ?? new StorageOptions();
        switch (storageOptions.Provider)
        {
            case FileStorageProvider.Cloudinary:
                services.AddScoped<IFileStorage, CloudinaryFileStorage>();
                break;
            case FileStorageProvider.AwsS3:
                services.AddScoped<IFileStorage, AwsS3FileStorage>();
                break;
            case FileStorageProvider.AzureBlob:
                services.AddScoped<IFileStorage, AzureBlobFileStorage>();
                break;
            case FileStorageProvider.Local:
            default:
                services.AddScoped<IFileStorage, LocalFileStorage>();
                break;
        }

        // ========== Payments ==========
        var paymentOptions = configuration.GetSection(PaymentOptions.SectionName).Get<PaymentOptions>() ?? new PaymentOptions();
        switch (paymentOptions.Provider)
        {
            case PaymentGatewayProvider.Paymob:
                services.AddScoped<IPaymentGateway, PaymobPaymentGateway>();
                break;
            case PaymentGatewayProvider.Fawry:
                services.AddScoped<IPaymentGateway, FawryPaymentGateway>();
                break;
            case PaymentGatewayProvider.Wallet:
                services.AddScoped<IPaymentGateway, WalletPaymentGateway>();
                break;
            case PaymentGatewayProvider.Stripe:
            default:
                services.AddScoped<IPaymentGateway, StripePaymentGateway>();
                break;
        }

        // ========== Maps (OpenStreetMap / Nominatim / OSRM / Overpass) ==========
        services.AddScoped<IMapService, OpenStreetMapService>();

        return services;
    }
}
'@

[System.IO.File]::WriteAllText("$base\DependencyInjection.cs", $content, [System.Text.Encoding]::UTF8)
Write-Host "DependencyInjection.cs rewritten with full adapter wiring."
