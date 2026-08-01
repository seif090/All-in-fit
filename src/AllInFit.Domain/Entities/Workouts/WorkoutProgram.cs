using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Workouts;

public sealed class WorkoutProgram : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public Guid? TrainerId { get; set; }
    public DifficultyLevel DifficultyLevel { get; set; }
    public int DurationInWeeks { get; set; }
    public int SessionsPerWeek { get; set; }
    public int? CaloriesTarget { get; set; }
    public string? CoverImageUrl { get; set; }
    public bool IsPublished { get; set; }
    public bool IsPremium { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public WorkoutCategory? Category { get; set; }

    private readonly List<WorkoutProgramExercise> _exercises = new();
    public IReadOnlyCollection<WorkoutProgramExercise> Exercises => _exercises.AsReadOnly();
}