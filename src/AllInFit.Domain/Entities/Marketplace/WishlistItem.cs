using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class WishlistItem : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid ProductId { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
    public Product? Product { get; set; }
}