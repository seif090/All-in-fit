using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Email).HasMaxLength(255).IsRequired();
        builder.HasIndex(e => e.Email).IsUnique().HasDatabaseName("IX_Users_Email");
        builder.Property(e => e.PasswordHash).HasMaxLength(500).IsRequired();
        builder.Property(e => e.FirstName).HasMaxLength(100);
        builder.Property(e => e.LastName).HasMaxLength(100);
        builder.Property(e => e.PhoneNumber).HasMaxLength(20);
        builder.HasIndex(e => e.PhoneNumber).HasDatabaseName("IX_Users_PhoneNumber");
        builder.Property(e => e.ProfilePictureUrl).HasMaxLength(500);
        builder.Property(e => e.Bio).HasMaxLength(1000);
        builder.Property(e => e.GoogleId).HasMaxLength(200);
        builder.Property(e => e.OtpCode).HasMaxLength(10);
        builder.Property(e => e.RefreshToken).HasMaxLength(500);
        builder.Property(e => e.AccountType).HasConversion<string>().HasMaxLength(50);
    }
}