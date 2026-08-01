using AllInFit.Domain.Entities.Gyms;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Gyms;

public sealed class GymConfiguration : IEntityTypeConfiguration<Gym>
{
    public void Configure(EntityTypeBuilder<Gym> builder)
    {
        builder.ToTable("Gyms");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(200).IsRequired();
        builder.HasIndex(e => e.Name).HasDatabaseName("IX_Gyms_Name");
        builder.Property(e => e.LegalName).HasMaxLength(200).IsRequired();
        builder.Property(e => e.LogoUrl).HasMaxLength(500);
        builder.Property(e => e.Website).HasMaxLength(500);
    }
}