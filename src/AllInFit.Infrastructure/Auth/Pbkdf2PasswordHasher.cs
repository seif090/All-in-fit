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