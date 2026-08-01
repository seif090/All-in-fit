using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserDevice : BaseEntity
{
    public Guid UserId { get; set; }
    public string DeviceId { get; set; } = string.Empty;
    public string? DeviceName { get; set; }
    public string? DeviceType { get; set; }
    public string? OperatingSystem { get; set; }
    public string? FcmToken { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime LastUsedAt { get; set; } = DateTime.UtcNow;
    public User? User { get; set; }
}