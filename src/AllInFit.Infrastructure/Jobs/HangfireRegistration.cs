using AllInFit.Infrastructure.Jobs;
using Hangfire;
using Hangfire.SqlServer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Hangfire.Dashboard;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;

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
            DashboardTitle = "All In Fit â€” Background Jobs",
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
/// Minimal dashboard authorization â€” only allow local requests in dev.
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