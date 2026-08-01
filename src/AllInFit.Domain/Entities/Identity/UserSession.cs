using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserSession : BaseEntity
{
    public Guid UserId { get; set; }
    public string? DeviceId { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Location { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? EndedAt { get; set; }
    public User? User { get; set; }

    public void End() { IsActive = false; EndedAt = DateTime.UtcNow; }
}