using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Workouts;

public sealed class WorkoutProgramExercise : BaseEntity
{
    public Guid WorkoutProgramId { get; set; }
    public Guid ExerciseId { get; set; }
    public int Sets { get; set; }
    public int Reps { get; set; }
    public int? RestSeconds { get; set; }
    public int SortOrder { get; set; }
    public WorkoutProgram? WorkoutProgram { get; set; }
    public Exercise? Exercise { get; set; }
}