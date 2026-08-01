using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserRole : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public User? User { get; set; }
    public Role? Role { get; set; }
}