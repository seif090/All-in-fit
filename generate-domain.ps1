$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# Enums
Write-File "$base\Enums\AccountType.cs" @"
namespace AllInFit.Domain.Enums;

public enum AccountType { User = 0, GymOwner = 1, Trainer = 2, Doctor = 3, Nutritionist = 4, RestaurantOwner = 5, PharmacyOwner = 6, SupplementSeller = 7, Admin = 8, SuperAdmin = 9 }
public enum Gender { Male = 0, Female = 1, Other = 2 }
public enum MembershipStatus { Active = 0, Expired = 1, Cancelled = 2, Pending = 3 }
public enum AppointmentStatus { Pending = 0, Confirmed = 1, Completed = 2, Cancelled = 3, Rescheduled = 4, NoShow = 5 }
public enum OrderStatus { Pending = 0, Confirmed = 1, Processing = 2, Shipped = 3, Delivered = 4, Cancelled = 5, Refunded = 6, Returned = 7 }
public enum PaymentStatus { Pending = 0, Succeeded = 1, Failed = 2, Refunded = 3, PartiallyRefunded = 4 }
public enum WalletTransactionType { Deposit = 0, Withdrawal = 1, Payment = 2, Refund = 3, Reward = 4, Referral = 5, Transfer = 6 }
public enum NotificationType { System = 0, Appointment = 1, Message = 2, Payment = 3, Promotion = 4, Reminder = 5, Challenge = 6, Reward = 7, Achievement = 8 }
public enum ChallengeType { Steps = 0, Workout = 1, Nutrition = 2, Weight = 3, Streak = 4, Custom = 5 }
public enum DifficultyLevel { Beginner = 0, Intermediate = 1, Advanced = 2, Elite = 3 }
public enum MealType { Breakfast = 0, Lunch = 1, Dinner = 2, Snack = 3, PreWorkout = 4, PostWorkout = 5 }
"@

# Identity Entities
Write-File "$base\Entities\Identity\Role.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class Role : BaseEntity
{
    private readonly List<UserRole> _userRoles = new();
    private readonly List<RolePermission> _rolePermissions = new();

    private Role() { }

    public Role(string name, string? description = null)
    {
        Name = name;
        Description = description;
        IsSystem = false;
    }

    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public bool IsSystem { get; private set; }

    public IReadOnlyCollection<UserRole> UserRoles => _userRoles.AsReadOnly();
    public IReadOnlyCollection<RolePermission> RolePermissions => _rolePermissions.AsReadOnly();

    public void AddPermission(Permission permission)
    {
        if (!_rolePermissions.Any(rp => rp.PermissionId == permission.Id))
            _rolePermissions.Add(new RolePermission { RoleId = Id, PermissionId = permission.Id });
    }

    public void RemovePermission(Permission permission)
    {
        var rp = _rolePermissions.FirstOrDefault(x => x.PermissionId == permission.Id);
        if (rp != null) _rolePermissions.Remove(rp);
    }
}
"@

Write-File "$base\Entities\Identity\Permission.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class Permission : BaseEntity
{
    private readonly List<RolePermission> _rolePermissions = new();

    private Permission() { }

    public Permission(string name, string? description = null, string? group = null)
    {
        Name = name;
        Description = description;
        Group = group;
    }

    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public string? Group { get; private set; }

    public IReadOnlyCollection<RolePermission> RolePermissions => _rolePermissions.AsReadOnly();
}
"@

Write-File "$base\Entities\Identity\UserRole.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserRole : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public User? User { get; set; }
    public Role? Role { get; set; }
}
"@

Write-File "$base\Entities\Identity\RolePermission.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class RolePermission : BaseEntity
{
    public Guid RoleId { get; set; }
    public Guid PermissionId { get; set; }
    public Role? Role { get; set; }
    public Permission? Permission { get; set; }
}
"@

Write-File "$base\Entities\Identity\RefreshToken.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string? DeviceId { get; set; }
    public bool IsRevoked { get; set; }
    public bool IsUsed { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }
    public string? ReplacedByToken { get; set; }
    public string? ReasonRevoked { get; set; }
    public User? User { get; set; }

    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
    public bool IsActive => !IsRevoked && !IsUsed && !IsExpired;

    public void MarkAsUsed() { IsUsed = true; }
    public void Revoke(string? reason = null, string? replacedBy = null)
    {
        IsRevoked = true;
        RevokedAt = DateTime.UtcNow;
        ReasonRevoked = reason;
        ReplacedByToken = replacedBy;
    }
}
"@

Write-File "$base\Entities\Identity\UserDevice.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserDevice : BaseEntity
{
    public Guid UserId { get; set; }
    public string DeviceId { get; set; } = string.Empty;
    public string? DeviceName { get; set; }
    public string? DeviceType { get; set; }
    public string? OperatingSystem { get; set; }
    public string? FcmToken { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime LastUsedAt { get; set; } = DateTime.UtcNow;
    public User? User { get; set; }
}
"@

Write-File "$base\Entities\Identity\UserSession.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Identity;

public sealed class UserSession : BaseEntity
{
    public Guid UserId { get; set; }
    public string? DeviceId { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Location { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? EndedAt { get; set; }
    public User? User { get; set; }

    public void End() { IsActive = false; EndedAt = DateTime.UtcNow; }
}
"@

Write-File "$base\Entities\Identity\User.cs" @"
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
"@

# Events
Write-File "$base\Events\UserEmailVerifiedDomainEvent.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Events;

public sealed record UserEmailVerifiedDomainEvent(Guid UserId, string Email) : DomainEvent;
"@

Write-File "$base\Events\UserRegisteredDomainEvent.cs" @"
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Events;

public sealed record UserRegisteredDomainEvent(Guid UserId, string Email, string FullName) : DomainEvent;
"@

Write-Host "Domain layer generated successfully!"
