using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Referrals;

public sealed class Referral : BaseEntity
{
    public Guid ReferrerUserId { get; set; }
    public Guid ReferredUserId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public bool IsRewarded { get; set; }
    public int RewardPoints { get; set; }
    public DateTime ReferredAt { get; set; } = DateTime.UtcNow;
}