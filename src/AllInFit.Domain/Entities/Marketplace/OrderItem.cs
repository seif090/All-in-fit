using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal LineTotal { get; set; }
    public Order? Order { get; set; }
    public Product? Product { get; set; }
}