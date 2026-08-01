using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Nutrition;

public sealed class MealPlan : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? NutritionistId { get; set; }
    public int DurationInDays { get; set; }
    public int DailyCalorieTarget { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public bool IsPublished { get; set; }
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
}