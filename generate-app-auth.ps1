$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

# ============================================================================
# 1) Domain: Role & RefreshToken specifications
# ============================================================================
Write-File "$root\AllInFit.Domain\Specifications\RoleSpecifications.cs" @'
using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class RoleByNameSpecification : BaseSpecification<Role>
{
    public RoleByNameSpecification(string name) : base(r => r.Name == name)
    {
        AddInclude("RolePermissions.Permission");
    }
}
'@

Write-File "$root\AllInFit.Domain\Specifications\RefreshTokenSpecifications.cs" @'
using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class ActiveRefreshTokenSpecification : BaseSpecification<RefreshToken>
{
    public ActiveRefreshTokenSpecification(string token)
        : base(t => t.Token == token && !t.IsRevoked && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
    {
    }
}

public sealed class ActiveTokensForUserSpecification : BaseSpecification<RefreshToken>
{
    public ActiveTokensForUserSpecification(Guid userId)
        : base(t => t.UserId == userId && !t.IsRevoked && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
    {
    }
}
'@

Write-File "$root\AllInFit.Domain\Specifications\UserSpecificationsExtra.cs" @'
using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class UserByPhoneSpecification : BaseSpecification<User>
{
    public UserByPhoneSpecification(string phoneNumber)
        : base(u => u.PhoneNumber != null && u.PhoneNumber == phoneNumber && !u.IsDeleted)
    {
    }
}
'@

# ============================================================================
# 2) Application: Ports (abstractions used by CQRS handlers)
# ============================================================================
Write-File "$root\AllInFit.Application\Ports\IPasswordHasher.cs" @'
namespace AllInFit.Application.Ports;

public interface IPasswordHasher
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string passwordHash);
}
'@

Write-File "$root\AllInFit.Application\Ports\ITokenService.cs" @'
using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Application.Ports;

public interface ITokenService
{
    TokenPair GenerateTokenPair(User user);
}

public
