using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class ProductCategory : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int SortOrder { get; set; }
}