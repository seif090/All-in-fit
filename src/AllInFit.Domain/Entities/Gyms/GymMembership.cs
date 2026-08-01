using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class GymMembership : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public Guid GymId { get; set; }
    public Guid? GymBranchId { get; set; }
    public Guid? PlanId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public MembershipStatus Status { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool AutoRenew { get; set; }
    public DateTime? CancelledAt { get; set; }
    public Gym? Gym { get; set; }
    public GymBranch? GymBranch { get; set; }

    public bool IsActive => Status == MembershipStatus.Active && EndDate >= DateTime.UtcNow;
}