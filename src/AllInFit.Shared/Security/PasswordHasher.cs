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