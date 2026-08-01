using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class UserBadge : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid BadgeId { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    public Badge? Badge { get; set; }
}