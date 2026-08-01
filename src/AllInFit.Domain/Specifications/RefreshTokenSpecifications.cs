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