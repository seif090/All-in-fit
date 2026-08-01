using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Order : SoftDeleteEntity
{
    private readonly List<OrderItem> _items = new();

    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public OrderStatus Status { get; set; }
    public decimal Subtotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal ShippingAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string? Currency { get; set; } = "USD";
    public string? ShippingAddress { get; set; }
    public string? BillingAddress { get; set; }
    public Guid? CouponId { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? ShippedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime? CancelledAt { get; set; }

    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();
    public void AddItem(OrderItem item) => _items.Add(item);
}