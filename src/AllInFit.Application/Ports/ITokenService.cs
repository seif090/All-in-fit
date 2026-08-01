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