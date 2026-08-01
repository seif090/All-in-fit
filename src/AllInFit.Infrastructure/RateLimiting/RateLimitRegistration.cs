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