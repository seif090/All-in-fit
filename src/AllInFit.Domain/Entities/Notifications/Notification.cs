using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Notifications;

public sealed class Notification : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Body { get; set; }
    public NotificationType Type { get; set; }
    public string? Data { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsSent { get; set; }
    public DateTime? SentAt { get; set; }
    public string? Channel { get; set; }
}