using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class Role : BaseEntity
{
    private readonly List<UserRole> _userRoles = new();
    private readonly List<RolePermission> _rolePermissions = new();

    private Role() { }

    public Role(string name, string? description = null)
    {
        Name = name;
        Description = description;
        IsSystem = false;
    }

    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public bool IsSystem { get; private set; }

    public IReadOnlyCollection<UserRole> UserRoles => _userRoles.AsReadOnly();
    public IReadOnlyCollection<RolePermission> RolePermissions => _rolePermissions.AsReadOnly();

    public void AddPermission(Permission permission)
    {
        if (!_rolePermissions.Any(rp => rp.PermissionId == permission.Id))
            _rolePermissions.Add(new RolePermission { RoleId = Id, PermissionId = permission.Id });
    }

    public void RemovePermission(Permission permission)
    {
        var rp = _rolePermissions.FirstOrDefault(x => x.PermissionId == permission.Id);
        if (rp != null) _rolePermissions.Remove(rp);
    }
}