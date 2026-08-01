using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Crm;

public sealed class CrmCustomer : SoftDeleteEntity
{
    public Guid? UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Tags { get; set; }
    public string? Notes { get; set; }
    public string? Source { get; set; }
    public DateTime? LastContactAt { get; set; }
    public decimal LifetimeValue { get; set; }
    public string? Segment { get; set; }
}