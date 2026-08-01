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