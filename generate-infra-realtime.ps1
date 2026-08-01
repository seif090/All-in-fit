$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

# Ensure all target directories exist before writing files.
foreach ($dir in @("$base\Realtime", "$base\Jobs", "$base\RateLimiting")) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

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
# 2. Hangfire Options + Jobs (port-based, config-gated)
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

# --- ExpiredMembershipJob ---
$expiredMembershipJob = @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Daily sweep that flags expired gym memberships so business rules
/// (access control, scheduling) can react accordingly.
/// </summary>
public sealed class ExpiredMembershipJob
{
    private readonly IUnitOfWork _unitOfWork;

    public ExpiredMembershipJob(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var repo = _unitOfWork.Repository<GymMembership>();
        var expired = await repo.GetListBySpecificationAsync(
            new ExpiredMembershipSpecification(DateTime.UtcNow), cancellationToken);

        foreach (var membership in expired)
        {
            membership.Status = MembershipStatus.Expired;
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }
}

internal sealed class ExpiredMembershipSpecification : BaseSpecification<GymMembership>
{
    public ExpiredMembershipSpecification(DateTime now)
        : base(m => m.Status == MembershipStatus.Active && m.EndDate <= now)
    {
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\ExpiredMembershipJob.cs", $expiredMembershipJob, [System.Text.Encoding]::UTF8)
Write-Host "Created ExpiredMembershipJob.cs"

# --- AppointmentReminderJob ---
$reminderJob = @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Appointments;
using AllInFit.Domain.Entities.Notifications;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Sends in-app + push reminders for upcoming appointments within the
/// configured window (default: next 24 hours).
/// </summary>
public sealed class AppointmentReminderJob
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPushNotificationService _push;
    private readonly ILogger<AppointmentReminderJob> _logger;

    public AppointmentReminderJob(
        IUnitOfWork unitOfWork,
        IPushNotificationService push,
        ILogger<AppointmentReminderJob> logger)
    {
        _unitOfWork = unitOfWork;
        _push = push;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var appointmentRepo = _unitOfWork.Repository<Appointment>();
        var notificationRepo = _unitOfWork.Repository<Notification>();

        var upcoming = await appointmentRepo.GetListBySpecificationAsync(
            new UpcomingAppointmentSpecification(now.AddHours(1), now.AddHours(24)), cancellationToken);

        foreach (var appointment in upcoming)
        {
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = appointment.UserId,
                Title = "Upcoming Appointment",
                Body = $"You have an appointment at {appointment.ScheduledStart:yyyy-MM-dd HH:mm}.",
                Type = NotificationType.Reminder,
                IsRead = false,
                IsSent = false,
                Channel = "inapp"
            };

            await notificationRepo.AddAsync(notification, cancellationToken);

            await _push.SendToDeviceAsync(
                appointment.UserId.ToString(),
                new PushNotificationPayload("Upcoming Appointment", notification.Body!));
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("AppointmentReminderJob dispatched {Count} reminder(s)", upcoming.Count);
    }
}

internal sealed class UpcomingAppointmentSpecification : BaseSpecification<Appointment>
{
    public UpcomingAppointmentSpecification(DateTime windowStart, DateTime windowEnd)
        : base(a => a.Status == AppointmentStatus.Confirmed
                    && a.ScheduledStart >= windowStart
                    && a.ScheduledStart <= windowEnd)
    {
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\AppointmentReminderJob.cs", $reminderJob, [System.Text.Encoding]::UTF8)
Write-Host "Created AppointmentReminderJob.cs"

# --- WalletDailyDigestJob (uses only public domain methods) ---
$walletJob = @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Wallet;
using AllInFit.Domain.Specifications;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Produces a daily summary of all active wallet balances so finance
/// teams can reconcile system state with payment providers.
/// </summary>
public sealed class WalletDailyDigestJob
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<WalletDailyDigestJob> _logger;

    public WalletDailyDigestJob(IUnitOfWork unitOfWork, ILogger<WalletDailyDigestJob> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var repo = _unitOfWork.Repository<Wallet>();
        var wallets = await repo.GetListBySpecificationAsync(new ActiveWalletsSpecification(), cancellationToken);

        var totalBalance = wallets.Sum(w => w.Balance);
        var totalRewardPoints = wallets.Sum(w => w.RewardPointsBalance);

        _logger.LogInformation(
            "WalletDailyDigestJob: {WalletCount} active wallets, total balance {TotalBalance}, total reward points {TotalRewardPoints}",
            wallets.Count, totalBalance, totalRewardPoints);
    }
}

internal sealed class ActiveWalletsSpecification : BaseSpecification<Wallet>
{
    public ActiveWalletsSpecification()
        : base(w => w.IsActive)
    {
    }
}
'@
[System.IO.File]::WriteAllText("$base\Jobs\WalletDailyDigestJob.cs", $walletJob, [System.Text.Encoding]::UTF8)
Write-Host "Created WalletDailyDigestJob.cs"

# =====================================================================
# 3. Rate Limiting Options
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

