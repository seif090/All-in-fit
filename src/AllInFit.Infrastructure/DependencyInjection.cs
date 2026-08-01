using AllInFit.Application.Ports;
using AllInFit.Infrastructure.Auth;
using AllInFit.Infrastructure.Caching;
using AllInFit.Infrastructure.Maps;
using AllInFit.Infrastructure.Messaging;
using AllInFit.Infrastructure.Notifications;
using AllInFit.Infrastructure.Jobs;
using AllInFit.Infrastructure.RateLimiting;
using AllInFit.Infrastructure.Realtime;
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
        services.Configure<GoogleAuthOptions>(configuration.GetSection(GoogleAuthOptions.SectionName));
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
        services.AddScoped<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IGoogleIdentityVerifier, GoogleIdentityVerifier>();
        services.AddScoped<IAuthSessionService, AuthSessionService>();

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
        // The storage adapters take the concrete StorageOptions in their constructor;
        // register it as a resolvable service backed by the IOptions binding.
        services.AddScoped(sp => sp.GetRequiredService<IOptions<StorageOptions>>().Value);

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

        // ========== Realtime (SignalR) ==========
        services.AddRealtimeServices();

        // ========== Rate Limiting ==========
        services.AddRateLimiting(configuration);

        // ========== Hangfire Background Jobs ==========
        services.AddHangfireJobs(configuration);

        return services;
    }
}