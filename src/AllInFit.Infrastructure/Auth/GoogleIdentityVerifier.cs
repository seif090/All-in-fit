using AllInFit.Application.Ports;
using Google.Apis.Auth;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Auth;

public sealed class GoogleIdentityVerifier : IGoogleIdentityVerifier
{
    private readonly GoogleAuthOptions _options;
    private readonly ILogger<GoogleIdentityVerifier> _logger;

    public GoogleIdentityVerifier(IOptions<GoogleAuthOptions> options, ILogger<GoogleIdentityVerifier> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task<GoogleIdentityProfile?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings();
            if (!string.IsNullOrWhiteSpace(_options.ClientId))
                settings.Audience = new[] { _options.ClientId };

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);
            return new GoogleIdentityProfile(payload.Subject, payload.Email, payload.GivenName, payload.FamilyName, payload.EmailVerified);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Google identity token validation failed");
            return null;
        }
    }
}