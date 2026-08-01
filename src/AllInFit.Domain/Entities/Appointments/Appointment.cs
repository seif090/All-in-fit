using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Appointments;

public sealed class Appointment : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public Guid? TrainerId { get; set; }
    public Guid? DoctorId { get; set; }
    public Guid? NutritionistId { get; set; }
    public DateTime ScheduledStart { get; set; }
    public DateTime ScheduledEnd { get; set; }
    public AppointmentStatus Status { get; set; }
    public string? Notes { get; set; }
    public string? MeetingUrl { get; set; }
    public bool IsOnline { get; set; }
    public decimal? Fee { get; set; }
    public string? Currency { get; set; } = "USD";
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? CancellationReason { get; set; }
}