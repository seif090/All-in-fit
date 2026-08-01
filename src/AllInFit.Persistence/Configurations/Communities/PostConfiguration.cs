using AllInFit.Domain.Entities.Communities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Communities;

public sealed class PostConfiguration : IEntityTypeConfiguration<Post>
{
    public void Configure(EntityTypeBuilder<Post> builder)
    {
        builder.ToTable("Posts");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Content).HasMaxLength(5000).IsRequired();
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasOne(e => e.Community).WithMany().HasForeignKey(e => e.CommunityId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(e => e.CommunityId).HasDatabaseName("IX_Posts_CommunityId");
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Posts_UserId");
    }
}