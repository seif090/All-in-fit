namespace AllInFit.Application.Ports;

public interface IGoogleIdentityVerifier
{
    Task<GoogleIdentityProfile?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}

public sealed record GoogleIdentityProfile(
    string Subject,
    string Email,
    string? GivenName,
    string? FamilyName,
    bool EmailVerified);