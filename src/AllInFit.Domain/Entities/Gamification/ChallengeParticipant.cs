using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class ChallengeParticipant : BaseEntity
{
    public Guid ChallengeId { get; set; }
    public Guid UserId { get; set; }
    public int Progress { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int Rank { get; set; }
    public Challenge? Challenge { get; set; }
}