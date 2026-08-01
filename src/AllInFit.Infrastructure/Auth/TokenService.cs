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