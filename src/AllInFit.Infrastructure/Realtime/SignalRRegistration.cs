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