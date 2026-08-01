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