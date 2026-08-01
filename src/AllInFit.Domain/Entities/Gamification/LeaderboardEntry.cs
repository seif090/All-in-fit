using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class LeaderboardEntry : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid? ChallengeId { get; set; }
    public Guid? CommunityId { get; set; }
    public int Score { get; set; }
    public int Rank { get; set; }
    public string? Period { get; set; }
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
}