using AllInFit.Domain.Entities.Gyms;

namespace AllInFit.Domain.Specifications;

public sealed class GymsNearbySpecification : BaseSpecification<GymBranch>
{
    public GymsNearbySpecification(double latitude, double longitude, double radiusMeters)
        : base(b => b.IsActive && !b.IsDeleted)
    {
        ApplyOrderBy(b => b.Name);
    }
}

public sealed class GymByIdWithBranchesSpecification : BaseSpecification<Gym>
{
    public GymByIdWithBranchesSpecification(Guid gymId) : base(g => g.Id == gymId)
    {
        AddInclude(g => g.Branches);
    }
}