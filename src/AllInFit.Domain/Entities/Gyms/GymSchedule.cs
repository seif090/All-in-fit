using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class GymSchedule : BaseEntity
{
    public Guid GymBranchId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan OpensAt { get; set; }
    public TimeSpan ClosesAt { get; set; }
    public bool IsClosed { get; set; }
    public GymBranch? GymBranch { get; set; }
}