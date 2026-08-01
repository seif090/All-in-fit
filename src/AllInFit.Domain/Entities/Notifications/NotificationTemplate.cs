using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Notifications;

public sealed class NotificationTemplate : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Subject { get; set; }
    public string? Body { get; set; }
    public string? EmailTemplate { get; set; }
    public string? SmsTemplate { get; set; }
    public string? PushTemplate { get; set; }
    public bool IsActive { get; set; } = true;
}