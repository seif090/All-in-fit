using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Product : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Sku { get; set; } = string.Empty;
    public Guid? BrandId { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public int StockQuantity { get; set; }
    public bool IsAvailable { get; set; } = true;
    public string? ImageUrl { get; set; }
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public bool IsSupplement { get; set; }
    public bool RequiresPrescription { get; set; }
    public Brand? Brand { get; set; }
}