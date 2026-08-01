using AllInFit.Domain.Entities.Appointments;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Appointments;

public sealed class AppointmentConfiguration : IEntityTypeConfiguration<Appointment>
{
    public void Configure(EntityTypeBuilder<Appointment> builder)
    {
        builder.ToTable("Appointments");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(e => e.Notes).HasMaxLength(1000);
        builder.Property(e => e.MeetingUrl).HasMaxLength(500);
        builder.Property(e => e.Fee).HasColumnType("decimal(18,2)");
        builder.Property(e => e.Currency).HasMaxLength(3).HasDefaultValue("USD");
        builder.Property(e => e.CancellationReason).HasMaxLength(500);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Appointments_UserId");
        builder.HasIndex(e => e.TrainerId).HasDatabaseName("IX_Appointments_TrainerId");
    }
}