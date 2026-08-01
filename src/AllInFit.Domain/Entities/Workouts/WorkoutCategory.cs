using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Workouts;

public sealed class WorkoutCategory : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
}