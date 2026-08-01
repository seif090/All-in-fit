using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Events;

namespace AllInFit.Domain.Entities.Identity;

public sealed class User : SoftDeleteEntity
{
    private readonly List<RefreshToken> _refreshTokens = new();
    private readonly List<UserDevice> _devices = new();
    private readonly List<UserRole> _userRoles = new();
    private readonly List<UserSession> _sessions = new();

    private User() { }

    public User(string email, string firstName, string lastName, string passwordHash)
    {
        Email = email; FirstName = firstName; LastName = lastName; PasswordHash = passwordHash;
        IsEmailVerified = false; IsActive = true; AccountType = AccountType.User;
    }

    public string Email { get; private set; } = string.Empty;
    public string FirstName { get; private set; } = string.Empty;
    public string LastName { get; private set; } = string.Empty;
    public string? PhoneNumber { get; private set; }
    public string? PhoneCountryCode { get; private set; }
    public bool IsPhoneVerified { get; private set; }
    public string PasswordHash { get; private set; } = string.Empty;
    public bool IsEmailVerified { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsLockedOut { get; private set; }
    public DateTime? LockoutEnd { get; private set; }
    public int AccessFailedCount { get; private set; }
    public DateTime? LastLoginAt { get; private set; }
    public string? ProfilePictureUrl { get; private set; }
    public string? Bio { get; private set; }
    public DateTime? DateOfBirth { get; private set; }
    public Gender Gender { get; private set; }
    public string? GoogleId { get; private set; }
    public bool IsGoogleAccount { get; private set; }
    public string? OtpCode { get; private set; }
    public DateTime? OtpExpiresAt { get; private set; }
    public AccountType AccountType { get; private set; }
    public string? RefreshToken { get; private set; }
    public DateTime? RefreshTokenExpiresAt { get; private set; }

    public IReadOnlyCollection<RefreshToken> RefreshTokens => _refreshTokens.AsReadOnly();
    public IReadOnlyCollection<UserDevice> Devices => _devices.AsReadOnly();
    public IReadOnlyCollection<UserRole> UserRoles => _userRoles.AsReadOnly();
    public IReadOnlyCollection<UserSession> Sessions => _sessions.AsReadOnly();
    public string FullName => $"{FirstName} {LastName}";

    public void VerifyEmail() { IsEmailVerified = true; AddDomainEvent(new UserEmailVerifiedDomainEvent(Id, Email)); }
    public void UpdateProfile(string fn, string ln, string? ph, string? bio, DateTime? dob, Gender g) { FirstName = fn; LastName = ln; PhoneNumber = ph; Bio = bio; DateOfBirth = dob; Gender = g; UpdatedAt = DateTime.UtcNow; }
    public void UpdatePassword(string hash) { PasswordHash = hash; UpdatedAt = DateTime.UtcNow; }
    public void RecordLogin() { LastLoginAt = DateTime.UtcNow; AccessFailedCount = 0; }
    public void RecordFailedLogin() { AccessFailedCount++; if (AccessFailedCount >= 5) { IsLockedOut = true; LockoutEnd = DateTime.UtcNow.AddMinutes(15); } }
    public void SetGoogleAccount(string googleId) { GoogleId = googleId; IsGoogleAccount = true; IsEmailVerified = true; }
    public void SetOtp(string code, DateTime expires) { OtpCode = code; OtpExpiresAt = expires; }
    public bool VerifyOtp(string code) { if (OtpCode != code || OtpExpiresAt < DateTime.UtcNow) return false; OtpCode = null; OtpExpiresAt = null; IsPhoneVerified = true; return true; }
    public void AddRole(Role role) { if (!_userRoles.Any(ur => ur.RoleId == role.Id)) _userRoles.Add(new UserRole { UserId = Id, RoleId = role.Id }); }
    public void RemoveRole(Role role) { var ur = _userRoles.FirstOrDefault(x => x.RoleId == role.Id); if (ur != null) _userRoles.Remove(ur); }
    public bool HasRole(string name) => _userRoles.Any(ur => ur.Role?.Name == name);
    public bool HasPermission(string perm) => _userRoles.Any(ur => ur.Role?.RolePermissions.Any(rp => rp.Permission.Name == perm) == true);
    public void AddDevice(UserDevice device) { var existing = _devices.FirstOrDefault(d => d.DeviceId == device.DeviceId); if (existing != null) _devices.Remove(existing); _devices.Add(device); }
    public void RemoveDevice(string deviceId) { var d = _devices.FirstOrDefault(x => x.DeviceId == deviceId); if (d != null) _devices.Remove(d); }
    public void Deactivate() { IsActive = false; DeletedAt = DateTime.UtcNow; }
    public void Reactivate() { IsActive = true; DeletedAt = null; }
}