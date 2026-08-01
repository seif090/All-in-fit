$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

# =====================================================================
# 1. SignalR Hubs — Notifications + Chat
# =====================================================================

$notificationHub = @'
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
'@
[System.IO.File]::WriteAllText("$base\Realtime\NotificationsHub.cs", $notificationHub, [System.Text.Encoding]::UTF8)
Write-Host "Created NotificationsHub.cs"

$chatHub = @'
using AllInFit.Domain.Entities.Chat;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace AllInFit.Infrastructure.Realtime;

/// <summary>
/// Real-time chat hub. Each conversation is a SignalR group keyed by "conv:{id}".
/// </summary>
[Authorize]
public sealed class ChatHub : Hub
{
    public const string HubPath = "/hubs/chat";
    private const string ConversationGroupPrefix = "conv:";

    public async Task JoinConversation(Guid conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"{ConversationGroupPrefix}{conversationId}");
    }

    public async Task LeaveConversation(Guid conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"{ConversationGroupPrefix}{conversationId}");
    }

    /// <summary>
    /// Broadcasts a message to everyone in the conversation group.
    /// </summary>
    public async Task SendMessage(Guid conversationId, string content, string? attachmentUrl = null)
    {
        var senderId = Context.UserIdentifier;
        if (string.IsNullOrWhiteSpace(senderId))
        {
            throw new HubException("Unauthenticated sender.");
        }

        var message = new
        {
            conversationId,
            senderId,
            content,
            attachmentUrl,
            sentAt = DateTime.UtcNow
        };

        await Clients.Group($"{ConversationGroupPrefix}{conversationId}")
            .SendAsync("receiveMessage", message);
    }
}

public static class ChatMessageMapper
{
    public static object ToTransport(ChatMessage message) => new
    {
        message.Id,
        message.ConversationId,
        message.SenderId,
        message.Content,
        message.AttachmentUrl,
        message.IsRead,
        message.ReadAt,
        message.IsEdited,
        message.EditedAt,
        message.ReplyToMessageId,
        message.CreatedAt
    };
}
'@
[System.IO.File]::WriteAllText("$base\Realtime\ChatHub.cs", $chatHub, [System.Text.Encoding]::UTF8)
Write-Host "Created ChatHub.cs"

# =====================================================================
# 2. Hangfire Background Jobs
# =====================================================================

$jobOptions = @'
namespace AllInFit.Infrastructure.Jobs;

public sealed class HangfireOptions
{
    public const string SectionName = "Hangfire";

    public bool Enabled { get; set; } = false;
    public string? DashboardPath { get; set; } = "/hangfire";
    public int WorkerCount { get; set; } = 4;
    public string[] Queues { get; set; } = ["default", "notifications", "payments", "reports"];
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\HangfireOptions.cs", $jobOptions, [System.Text.Encoding]::UTF8)
Write-Host "Created HangfireOptions.cs"

$expiredMembershipJob = @'
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Enums;
using AllInFit.Persistence.Data;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Daily sweep that flags expired gym memberships and releases any
/// resources blocked by them.
/// </summary>
public sealed class ExpiredMembershipJob
{
    private readonly ApplicationDbContext _db;

    public ExpiredMembershipJob(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var expired = _db.Set<GymMembership>()
            .Where(m => m.Status == MembershipStatus.Active && m.EndDate <= now);

        foreach (var membership in expired)
        {
            membership.Status = MembershipStatus.Expired;
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\ExpiredMembershipJob.cs", $expiredMembershipJob, [System.Text.Encoding]::UTF8)
Write-Host "Created ExpiredMembershipJob.cs"

$reminderJob = @'
using AllInFit.Domain.Entities.Appointments;
using AllInFit.Domain.Entities.Notifications;
using AllInFit.Domain.Enums;
using AllInFit.Persistence.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using AllInFit.Shared.Contracts;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Sends in-app + push reminders for upcoming appointments within the
/// configured window (default: next 24 hours).
/// </summary>
public sealed class AppointmentReminderJob
{
    private readonly ApplicationDbContext _db;
    private readonly IPushNotificationService _push;
    private readonly ILogger<AppointmentReminderJob> _logger;

    public AppointmentReminderJob(
        ApplicationDbContext db,
        IPushNotificationService push,
        ILogger<AppointmentReminderJob> logger)
    {
        _db = db;
        _push = push;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var windowStart = now.AddHours(1);
        var windowEnd = now.AddHours(24);

        var upcoming = await _db.Set<Appointment>()
            .Where(a => a.Status == AppointmentStatus.Confirmed
                        && a.StartTime >= windowStart
                        && a.StartTime <= windowEnd)
            .ToListAsync(cancellationToken);

        foreach (var appointment in upcoming)
        {
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = appointment.UserId,
                Title = "Upcoming Appointment",
                Body = $"You have an appointment at {appointment.StartTime:yyyy-MM-dd HH:mm}.",
                Type = NotificationType.Reminder,
                IsRead = false,
                IsSent = false,
                Channel = "inapp"
            };

            _db.Set<Notification>().Add(notification);

            await _push.SendToDeviceAsync(
                appointment.UserId.ToString(),
                new PushNotificationPayload("Upcoming Appointment", notification.Body!)
            );
        }

        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("AppointmentReminderJob dispatched {Count} reminder(s)", upcoming.Count);
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\AppointmentReminderJob.cs", $reminderJob, [System.Text.Encoding]::UTF8)
Write-Host "Created AppointmentReminderJob.cs"

$rewardJob = @'
using AllInFit.Domain.Entities.Gamification;
using AllInFit.Domain.Entities.Wallet;
using AllInFit.Domain.Enums;
using AllInFit.Persistence.Data;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Processes reward-point redemption requests in a nightly batch.
/// </summary>
public sealed class RewardPointsJob
{
    private readonly ApplicationDbContext _db;

    public RewardPointsJob(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var pending = _db.Set<RewardPoint>()
            .Where(r => r.Status == RewardPointStatus.Pending);

        foreach (var point in pending)
        {
            point.Status = RewardPointStatus.Redeemed;
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\RewardPointsJob.cs", $rewardJob, [System.Text.Encoding]::UTF8)
Write-Host "Created RewardPointsJob.cs"

# =====================================================================
# 3. Rate Limiting
# =====================================================================

$rateLimitOptions = @'
namespace AllInFit.Infrastructure.RateLimiting;

public sealed class RateLimitOptions
{
    public const string SectionName = "RateLimiting";

    public bool Enabled { get; set; } = true;
    public int PermitLimit { get; set; } = 100;
    public int WindowSeconds { get; set; } = 60;
    public int QueueLimit { get; set; } = 10;
}
'@
[System.IO.File]::WriteAllText("$base\RateLimiting\RateLimitOptions.cs", $rateLimitOptions, [System.Text.Encoding]::UTF8)
Write-Host "Created RateLimitOptions.cs"

Write-Host "Realtime + Jobs + RateLimiting files generated."

