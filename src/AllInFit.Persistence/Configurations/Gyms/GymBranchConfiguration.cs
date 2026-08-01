using AllInFit.Domain.Entities.Gyms;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Gyms;

public sealed class GymBranchConfiguration : IEntityTypeConfiguration<GymBranch>
{
    public void Configure(EntityTypeBuilder<GymBranch> builder)
    {
        builder.ToTable("GymBranches");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(200).IsRequired();
        builder.Property(e => e.Address).HasMaxLength(500);
        builder.Property(e => e.City).HasMaxLength(100);
        builder.Property(e => e.State).HasMaxLength(100);
        builder.Property(e => e.Country).HasMaxLength(100);
        builder.Property(e => e.PostalCode).HasMaxLength(20);
        builder.Property(e => e.PhoneNumber).HasMaxLength(20);
        builder.Property(e => e.Email).HasMaxLength(255);
        builder.HasOne(e => e.Gym).WithMany(g => g.Branches).HasForeignKey(e => e.GymId).OnDelete(DeleteBehavior.Cascade);
    }
}