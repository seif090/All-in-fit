using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class TrainerAvailability : BaseEntity
{
    public Guid TrainerId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsBooked { get; set; }
    public Trainer? Trainer { get; set; }
}