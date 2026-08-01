$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

# =====================================================================
# 1. Hangfire registration extension
# =====================================================================
$hangfireExt = @'
using AllInFit.Infrastructure.Jobs;
using Hangfire;
using Hangfire.SqlServer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Jobs;

public static class HangfireRegistration
{
    public static IServiceCollection AddHangfireJobs(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var options = configuration.GetSection(HangfireOptions.SectionName).Get<HangfireOptions>() ?? new HangfireOptions();
        if (!options.Enabled)
        {
            return services;
        }

        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("DefaultConnection must be configured when Hangfire is enabled.");

        services.AddHangfire(config => config
            .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
            .UseSimpleAssemblyNameTypeSerializer()
            .UseRecommendedSerializerSettings()
            .UseSqlServerStorage(connectionString, new SqlServerStorageOptions
            {
                CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
                SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
                QueuePollInterval = TimeSpan.Zero,
                UseRecommendedIsolationLevel = true,
                DisableGlobalLocks = true
            }));

        services.AddHangfireServer(serverOptions =>
        {
            serverOptions.WorkerCount = options.WorkerCount;
            serverOptions.Queues = options.Queues;
        });

        // Register job classes for DI
        services.AddScoped<ExpiredMembershipJob>();
        services.AddScoped<AppointmentReminderJob>();
        services.AddScoped<WalletDailyDigestJob>();

        return services;
    }

    public static IApplicationBuilder UseHangfireDashboardJobs(
        this IApplicationBuilder app,
        IConfiguration configuration)
    {
        var options = configuration.GetSection(HangfireOptions.SectionName).Get<HangfireOptions>() ?? new HangfireOptions();
        if (!options.Enabled || string.IsNullOrWhiteSpace(options.DashboardPath))
        {
            return app;
        }

        app.UseHangfireDashboard(options.DashboardPath, new DashboardOptions
        {
            DashboardTitle = "All In Fit — Background Jobs",
            Authorization = [new HangfireDashboardAuthorization()]
        });

        RecurringJob.AddOrUpdate<ExpiredMembershipJob>(
            "expired-memberships-daily",
            job => job.RunAsync(CancellationToken.None),
            Cron.Daily(2, 0));

        RecurringJob.AddOrUpdate<AppointmentReminderJob>(
            "appointment-reminders-hourly",
            job => job.RunAsync(CancellationToken.None),
            Cron.Hourly(5));

        RecurringJob.AddOrUpdate<WalletDailyDigestJob>(
            "wallet-digest-daily",
            job => job.RunAsync(CancellationToken.None),
            Cron.Daily(23, 0));

        return app;
    }
}

/// <summary>
/// Minimal dashboard authorization — only allow local requests in dev.
/// Replace with a proper role check in production.
/// </summary>
public sealed class HangfireDashboardAuthorization : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        var http = context.GetHttpContext();
        return http.Connection.LocalIpAddress is not null &&
               http.Connection.RemoteIpAddress is not null &&
               http.Connection.LocalIpAddress.Equals(http.Connection.RemoteIpAddress);
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\HangfireRegistration.cs", $hangfireExt, [System.Text.Encoding]::UTF8)
Write-Host "Created HangfireRegistration.cs"

# =====================================================================
# 2. SignalR registration extension
# =====================================================================
$signalrExt = @'
using AllInFit.Infrastructure.Realtime;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Infrastructure.Realtime;

public static class SignalRRegistration
{
    public static IServiceCollection AddRealtimeServices(this IServiceCollection services)
    {
        services.AddSignalR(options =>
        {
            options.EnableDetailedErrors = false;
            options.MaximumReceiveMessageSize = 64 * 1024; // 64KB
        });

        return services;
    }

    public static IApplicationBuilder MapRealtimeHubs(this IApplicationBuilder app)
    {
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapHub<NotificationsHub>(NotificationsHub.HubPath);
            endpoints.MapHub<ChatHub>(ChatHub.HubPath);
        });

        return app;
    }

    public static IUserIdProvider AllInFitUserIdProvider() => new ClaimsUserIdProvider();
}

public sealed class ClaimsUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
        => connection.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
           ?? connection.User?.FindFirst("sub")?.Value;
}
'@
[System.IO.File]::WriteAllText("$base\Realtime\SignalRRegistration.cs", $signalrExt, [System.Text.Encoding]::UTF8)
Write-Host "Created SignalRRegistration.cs"

# =====================================================================
# 3. Rate Limiting registration extension
# =====================================================================
$rateLimitExt = @'
using System.Threading.RateLimiting;
using AllInFit.Infrastructure.RateLimiting;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Infrastructure.RateLimiting;

public static class RateLimitRegistration
{
    public static IServiceCollection AddRateLimiting(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var options = configuration.GetSection(RateLimitOptions.SectionName).Get<RateLimitOptions>() ?? new RateLimitOptions();
        if (!options.Enabled)
        {
            return services;
        }

        services.Configure<RateLimitOptions>(configuration.GetSection(RateLimitOptions.SectionName));

        services.AddRateLimiter(limiter =>
        {
            limiter.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            limiter.AddPolicy("api", context =>
            {
                var limit = options.PermitLimit;
                var window = TimeSpan.FromSeconds(options.WindowSeconds);

                // Per-IP + per-user if authenticated.
                var key = context.User?.Identity?.IsAuthenticated == true
                    ? context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                      ?? context.Connection.RemoteIpAddress?.ToString()
                      ?? "anonymous"
                    : context.Connection.RemoteIpAddress?.ToString() ?? "anonymous";

                return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = limit,
                    Window = window,
                    QueueLimit = options.QueueLimit,
                    AutoReplenishment = true
                });
            });

            limiter.OnRejected = async (context, cancellationToken) =>
            {
                context.HttpContext.Response.Headers["Retry-After"] = "60";
                await context.HttpContext.Response.WriteAsJsonAsync(
                    new { error = "Rate limit exceeded. Please retry later." }, cancellationToken);
            };
        });

        return services;
    }
}
'@
[System.IO.File]::WriteAllText("$base\RateLimiting\RateLimitRegistration.cs", $rateLimitExt, [System.Text.Encoding]::UTF8)
Write-Host "Created RateLimitRegistration.cs"

Write-Host "Hangfire + SignalR + RateLimit registration extensions generated."

