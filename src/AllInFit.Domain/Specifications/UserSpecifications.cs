using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class UserByEmailSpecification : BaseSpecification<User>
{
    public UserByEmailSpecification(string email) : base(u => u.Email.ToLower() == email.ToLower())
    {
        AddInclude(u => u.UserRoles);
        AddInclude("UserRoles.Role");
        AddInclude("UserRoles.Role.RolePermissions");
        AddInclude("UserRoles.Role.RolePermissions.Permission");
    }
}

public sealed class UserByIdSpecification : BaseSpecification<User>
{
    public UserByIdSpecification(Guid userId) : base(u => u.Id == userId)
    {
        AddInclude(u => u.UserRoles);
        AddInclude("UserRoles.Role");
        AddInclude("UserRoles.Role.RolePermissions");
        AddInclude("UserRoles.Role.RolePermissions.Permission");
        AddInclude(u => u.Devices);
    }
}

public sealed class ActiveUsersSpecification : BaseSpecification<User>
{
    public ActiveUsersSpecification() : base(u => u.IsActive && !u.IsDeleted)
    {
        ApplyOrderByDescending(u => u.CreatedAt);
    }
}