$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

Write-File "$root\AllInFit.Shared\Security\PasswordHasher.cs" @'
using System.Security.Cryptography;

namespace AllInFit.Shared.Security;

/// <summary>
/// PBKDF2 (Rfc2898) password hashing helper used across the platform.
/// Format: {iterations}.{saltBase64}.{hashBase64}
/// </summary>
public static class PasswordHasher
{
    private const int DefaultIterations = 100_000;
    private const int SaltSize = 16;
    private const int KeySize = 32;
    private const char Delimiter = '.';

    public static string HashPassword(string password, int iterations = DefaultIterations)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var key = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, KeySize);
        return string.Join(Delimiter, iterations, Convert.ToBase64String(salt), Convert.ToBase64String(key));
    }

    public static bool VerifyPassword(string password, string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(passwordHash)) return false;
        var segments = passwordHash.Split(Delimiter, 3);
        if (segments.Length != 3) return false;
        if (!int.TryParse(segments[0], out var iterations) || iterations < 10_000) return false;
        try
        {
            var salt = Convert.FromBase64String(segments[1]);
            var expected = Convert.FromBase64String(segments[2]);
            var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, expected.Length);
            return CryptographicOperations.FixedTimeEquals(actual, expected);
        }
        catch (FormatException)
        {
            return false;
        }
    }
}
'@

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

public record TokenPair(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpiresAt,
    DateTime RefreshTokenExpiresAt);
'@

Write-Host "generate-auth-1.ps1 complete."

