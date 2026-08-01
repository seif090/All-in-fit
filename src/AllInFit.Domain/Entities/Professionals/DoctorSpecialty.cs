using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class DoctorSpecialty : BaseEntity
{
    public Guid DoctorId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Doctor? Doctor { get; set; }
}