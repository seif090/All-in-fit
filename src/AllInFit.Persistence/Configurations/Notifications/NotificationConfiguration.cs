using AllInFit.Domain.Entities.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Notifications;

public sealed class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("Notifications");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Title).HasMaxLength(200).IsRequired();
        builder.Property(e => e.Body).HasMaxLength(2000);
        builder.Property(e => e.Type).HasConversion<string>().HasMaxLength(50);
        builder.Property(e => e.Channel).HasMaxLength(50);
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Notifications_UserId");
        builder.HasIndex(e => new { e.UserId, e.IsRead }).HasDatabaseName("IX_Notifications_User_Read");
    }
}