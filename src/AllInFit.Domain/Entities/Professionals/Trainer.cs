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