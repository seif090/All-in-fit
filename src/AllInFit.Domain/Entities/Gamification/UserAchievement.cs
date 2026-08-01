using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class UserAchievement : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid AchievementId { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    public Achievement? Achievement { get; set; }
}