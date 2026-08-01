using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Daily sweep that flags expired gym memberships so business rules
/// (access control, scheduling) can react accordingly.
/// </summary>
public sealed class ExpiredMembershipJob
{
    private readonly IUnitOfWork _unitOfWork;

    public ExpiredMembershipJob(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var repo = _unitOfWork.Repository<GymMembership>();
        var expired = await repo.GetListBySpecificationAsync(
            new ExpiredMembershipSpecification(DateTime.UtcNow), cancellationToken);

        foreach (var membership in expired)
        {
            membership.Status = MembershipStatus.Expired;
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }
}

internal sealed class ExpiredMembershipSpecification : BaseSpecification<GymMembership>
{
    public ExpiredMembershipSpecification(DateTime now)
        : base(m => m.Status == MembershipStatus.Active && m.EndDate <= now)
    {
    }
}