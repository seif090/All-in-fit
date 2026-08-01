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