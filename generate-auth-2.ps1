$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

Write-File "$root\AllInFit.Infrastructure\Auth\Pbkdf2PasswordHasher.cs" @'
using AllInFit.Application.Ports;

namespace AllInFit.Infrastructure.Auth;

/// <summary>
/// Password hasher implementation backed by the shared PBKDF2 helper.
/// </summary>
public sealed class Pbkdf2PasswordHasher : IPasswordHasher
{
    public string HashPassword(string password) => Shared.Security.PasswordHasher.HashPassword(password);

    public bool VerifyPassword(string password, string passwordHash) =>
        Shared.Security.PasswordHasher.VerifyPassword(password, passwordHash);
}
'@

Write-File "$root\AllInFit.Infrastructure\Auth\TokenService.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Auth;

/// <summary>
/// Generates access + refresh token pairs backed by the JWT provider.
/// </summary>
public sealed class TokenService : ITokenService
{
    private readonly IJwtProvider _jwtProvider;
    private readonly JwtOptions _options;

    public TokenService(IJwtProvider jwtProvider, IOptions<JwtOptions> options)
    {
        _jwtProvider = jwtProvider;
        _options = options.Value;
    }

    public TokenPair GenerateTokenPair(User user)
    {
        var accessToken = _jwtProvider.GenerateAccessToken(user);
        var refreshToken = _jwtProvider.GenerateRefreshToken();
        var now = DateTime.UtcNow;
        return new TokenPair(
            accessToken,
            refreshToken,
            now.AddMinutes(_options.AccessTokenExpirationMinutes),
            now.AddDays(_options.RefreshTokenExpirationDays));
    }
}
'@

Write-Host "generate-auth-2.ps1 complete."

