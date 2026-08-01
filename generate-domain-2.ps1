$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"
$shared = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Shared"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== FIX corrupted shared contracts =====
Write-File "$shared\Contracts\INotificationService.cs" @'
namespace AllInFit.Shared.Contracts;

public interface IEmailSender
{
    Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default);
}

public record EmailMessage(
    string To,
    string Subject,
    string Body,
    bool IsHtml = true,
    string? From = null,
    string? ReplyTo = null,
    IReadOnlyList<string>? Cc = null,
    IReadOnlyList<string>? Bcc = null,
    IReadOnlyList<EmailAttachment>? Attachments = null);

public record EmailAttachment(string FileName, byte[] Content, string ContentType);

public interface ISmsSender
{
    Task SendAsync(SmsMessage message, CancellationToken cancellationToken = default);
}

public record SmsMessage(string PhoneNumber, string Text, string? SenderId = null);

public interface IPushNotificationService
{
    Task SendAsync(PushNotificationMessage message, CancellationToken cancellationToken = default);
    Task SendToDeviceAsync(string deviceToken, PushNotificationPayload payload, CancellationToken cancellationToken = default);
    Task SendToTopicAsync(string topic, PushNotificationPayload payload, CancellationToken cancellationToken = default);
}

public record PushNotificationMessage(
    string UserId,
    string Title,
    string Body,
    string? Data = null,
    string? ImageUrl = null);

public record PushNotificationPayload(
    string Title,
    string Body,
    Dictionary<string, string>? Data = null,
    string? ImageUrl = null,
    string? ClickAction = null);
'@

# ===== Gym aggregates =====
Write-File "$base\Entities\Gyms\Gym.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class Gym : SoftDeleteEntity
{
    private readonly List<GymBranch> _branches = new();

    private Gym() { }

    public Gym(string name, string legalName, string? logoUrl, string? description, string? website, Guid ownerUserId)
    {
        Name = name;
        LegalName = legalName;
        LogoUrl = logoUrl;
        Description = description;
        Website = website;
        OwnerUserId = ownerUserId;
        IsVerified = false;
        IsActive = true;
    }

    public string Name { get; private set; } = string.Empty;
    public string LegalName { get; private set; } = string.Empty;
    public string? LogoUrl { get; private set; }
    public string? Description { get; private set; }
    public string? Website { get; private set; }
    public Guid OwnerUserId { get; private set; }
    public bool IsVerified { get; private set; }
    public bool IsActive { get; private set; }
    public double? Rating { get; private set; }
    public int ReviewCount { get; private set; }
    public Guid? PrimaryBranchId { get; private set; }

    public IReadOnlyCollection<GymBranch> Branches => _branches.AsReadOnly();

    public void AddBranch(GymBranch branch) => _branches.Add(branch);
    public void Verify() { IsVerified = true; UpdatedAt = DateTime.UtcNow; }
    public void Deactivate() { IsActive = false; UpdatedAt = DateTime.UtcNow; }
    public void UpdateRating(double rating, int count) { Rating = rating; ReviewCount = count; UpdatedAt = DateTime.UtcNow; }
}
'@

Write-File "$base\Entities\Gyms\GymBranch.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class GymBranch : SoftDeleteEntity
{
    public Guid GymId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
    public TimeSpan? OpensAt { get; set; }
    public TimeSpan? ClosesAt { get; set; }
    public bool IsOpen24Hours { get; set; }
    public Gym? Gym { get; set; }
}
'@

Write-File "$base\Entities\Gyms\GymMembership.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class GymMembership : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public Guid GymId { get; set; }
    public Guid? GymBranchId { get; set; }
    public Guid? PlanId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public MembershipStatus Status { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool AutoRenew { get; set; }
    public DateTime? CancelledAt { get; set; }
    public Gym? Gym { get; set; }
    public GymBranch? GymBranch { get; set; }

    public bool IsActive => Status == MembershipStatus.Active && EndDate >= DateTime.UtcNow;
}
'@

Write-File "$base\Entities\Gyms\GymSchedule.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class GymSchedule : BaseEntity
{
    public Guid GymBranchId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan OpensAt { get; set; }
    public TimeSpan ClosesAt { get; set; }
    public bool IsClosed { get; set; }
    public GymBranch? GymBranch { get; set; }
}
'@

# ===== Fitness Professionals =====
Write-File "$base\Entities\Professionals\Trainer.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class Trainer : SoftDeleteEntity
{
    private readonly List<TrainerCertificate> _certificates = new();
    private readonly List<TrainerAvailability> _availability = new();

    public Guid UserId { get; set; }
    public Guid? GymId { get; set; }
    public string? Bio { get; set; }
    public string? Specialty { get; set; }
    public int YearsOfExperience { get; set; }
    public double? HourlyRate { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool IsVerified { get; set; }
    public bool IsAvailable { get; set; } = true;
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public string? ProfilePictureUrl { get; set; }

    public IReadOnlyCollection<TrainerCertificate> Certificates => _certificates.AsReadOnly();
    public IReadOnlyCollection<TrainerAvailability> Availability => _availability.AsReadOnly();

    public void AddCertificate(TrainerCertificate certificate) => _certificates.Add(certificate);
    public void AddAvailability(TrainerAvailability availability) => _availability.Add(availability);
}
'@

Write-File "$base\Entities\Professionals\TrainerCertificate.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class TrainerCertificate : BaseEntity
{
    public Guid TrainerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? IssuedBy { get; set; }
    public DateTime IssuedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? CertificateUrl { get; set; }
    public string? VerificationCode { get; set; }
    public bool IsVerified { get; set; }
    public Trainer? Trainer { get; set; }
}
'@

Write-File "$base\Entities\Professionals\TrainerAvailability.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class TrainerAvailability : BaseEntity
{
    public Guid TrainerId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsBooked { get; set; }
    public Trainer? Trainer { get; set; }
}
'@

Write-File "$base\Entities\Professionals\Doctor.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class Doctor : SoftDeleteEntity
{
    private readonly List<DoctorSpecialty> _specialties = new();

    public Guid UserId { get; set; }
    public string? LicenseNumber { get; set; }
    public string? Bio { get; set; }
    public int YearsOfExperience { get; set; }
    public double? ConsultationFee { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool IsVerified { get; set; }
    public bool IsAvailable { get; set; } = true;
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public string? ProfilePictureUrl { get; set; }

    public IReadOnlyCollection<DoctorSpecialty> Specialties => _specialties.AsReadOnly();
    public void AddSpecialty(DoctorSpecialty specialty) => _specialties.Add(specialty);
}
'@

Write-File "$base\Entities\Professionals\DoctorSpecialty.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class DoctorSpecialty : BaseEntity
{
    public Guid DoctorId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Doctor? Doctor { get; set; }
}
'@

Write-File "$base\Entities\Professionals\Nutritionist.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class Nutritionist : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public string? LicenseNumber { get; set; }
    public string? Bio { get; set; }
    public int YearsOfExperience { get; set; }
    public double? SessionFee { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool IsVerified { get; set; }
    public bool IsAvailable { get; set; } = true;
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public string? ProfilePictureUrl { get; set; }
}
'@

Write-Host "Domain layer part 2 generated successfully!"
