using AllInFit.Domain.Entities.Reviews;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Reviews;

public sealed class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.ToTable("Reviews");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Rating).IsRequired();
        builder.Property(e => e.Title).HasMaxLength(200);
        builder.Property(e => e.Comment).HasMaxLength(2000);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Reviews_UserId");
        builder.HasIndex(e => e.GymId).HasDatabaseName("IX_Reviews_GymId");
        builder.HasIndex(e => e.ProductId).HasDatabaseName("IX_Reviews_ProductId");
    }
}