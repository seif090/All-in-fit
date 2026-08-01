using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("OrderItems");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.ProductName).HasMaxLength(300).IsRequired();
        builder.Property(e => e.UnitPrice).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.LineTotal).HasColumnType("decimal(18,2)").IsRequired();
        builder.HasOne(e => e.Order).WithMany(o => o.Items).HasForeignKey(e => e.OrderId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(e => e.Product).WithMany().HasForeignKey(e => e.ProductId).OnDelete(DeleteBehavior.Restrict);
    }
}