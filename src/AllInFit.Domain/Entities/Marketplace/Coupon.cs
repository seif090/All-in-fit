using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Coupon : SoftDeleteEntity
{
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal? DiscountPercent { get; set; }
    public decimal? MinOrderAmount { get; set; }
    public DateTime? ValidFrom { get; set; }
    public DateTime? ValidTo { get; set; }
    public int? MaxUses { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; } = true;

    public bool IsValid =>
        IsActive &&
        (ValidFrom == null || ValidFrom <= DateTime.UtcNow) &&
        (ValidTo == null || ValidTo >= DateTime.UtcNow) &&
        (MaxUses == null || UsedCount < MaxUses);
}