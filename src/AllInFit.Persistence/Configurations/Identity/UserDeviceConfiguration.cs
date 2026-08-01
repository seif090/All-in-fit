using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.ToTable("UserDevices");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.DeviceId).HasMaxLength(200).IsRequired();
        builder.Property(e => e.DeviceName).HasMaxLength(200);
        builder.Property(e => e.DeviceType).HasMaxLength(50);
        builder.Property(e => e.FcmToken).HasMaxLength(500);
        builder.HasOne(e => e.User).WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}