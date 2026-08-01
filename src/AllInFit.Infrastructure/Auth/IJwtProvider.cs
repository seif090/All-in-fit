namespace AllInFit.Infrastructure.Auth;

public interface IJwtProvider
{
    string GenerateAccessToken(Domain.Entities.Identity.User user);
    string GenerateRefreshToken();
    System.Security.Claims.ClaimsPrincipal? ValidateToken(string token);
}