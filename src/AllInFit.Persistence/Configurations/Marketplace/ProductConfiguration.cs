using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(300).IsRequired();
        builder.HasIndex(e => e.Name).HasDatabaseName("IX_Products_Name");
        builder.Property(e => e.Description).HasMaxLength(2000);
        builder.Property(e => e.Price).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.Currency).HasMaxLength(3).IsRequired().HasDefaultValue("USD");
        builder.Property(e => e.Sku).HasMaxLength(100);
        builder.HasIndex(e => e.Sku).IsUnique().HasDatabaseName("IX_Products_Sku").HasFilter("[Sku] IS NOT NULL AND [Sku] <> ''");
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasOne(e => e.Brand).WithMany().HasForeignKey(e => e.BrandId).OnDelete(DeleteBehavior.SetNull);
    }
}