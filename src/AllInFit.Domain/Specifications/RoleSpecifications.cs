using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class RoleByNameSpecification : BaseSpecification<Role>
{
    public RoleByNameSpecification(string name) : base(r => r.Name == name)
    {
        AddInclude("RolePermissions.Permission");
    }
}