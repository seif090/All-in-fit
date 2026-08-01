using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class Permission : BaseEntity
{
    private readonly List<RolePermission> _rolePermissions = new();

    private Permission() { }

    public Permission(string name, string? description = null, string? group = null)
    {
        Name = name;
        Description = description;
        Group = group;
    }

    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public string? Group { get; private set; }

    public IReadOnlyCollection<RolePermission> RolePermissions => _rolePermissions.AsReadOnly();
}