using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class RolePermission : BaseEntity
{
    public Guid RoleId { get; set; }
    public Guid PermissionId { get; set; }
    public Role? Role { get; set; }
    public Permission? Permission { get; set; }
}