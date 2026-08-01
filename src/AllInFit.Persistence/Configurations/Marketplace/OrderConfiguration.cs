using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("Orders");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.OrderNumber).HasMaxLength(50).IsRequired();
        builder.HasIndex(e => e.OrderNumber).IsUnique().HasDatabaseName("IX_Orders_OrderNumber");
        builder.Property(e => e.Subtotal).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.DiscountAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.ShippingAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.TaxAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.TotalAmount).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.Currency).HasMaxLength(3).HasDefaultValue("USD");
        builder.Property(e => e.ShippingAddress).HasMaxLength(500);
        builder.Property(e => e.BillingAddress).HasMaxLength(500);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50);
    }
}