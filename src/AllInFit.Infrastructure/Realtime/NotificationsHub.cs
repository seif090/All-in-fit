using Microsoft.AspNetCore.SignalR;

namespace AllInFit.Infrastructure.Realtime;

/// <summary>
/// Live notification delivery hub. Users subscribe via their user id.
/// Clients invoke: hubConnection.on('sendNotification', handler)
/// </summary>
public sealed class NotificationsHub : Hub
{
    public const string HubPath = "/hubs/notifications";

    public override async Task OnConnectedAsync()
    {
        // Group this connection by the authenticated user id so pushes
        // can fan out to every device belonging to that user.
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrWhiteSpace(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, userId);
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrWhiteSpace(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, userId);
        }

        await base.OnDisconnectedAsync(exception);
    }
}