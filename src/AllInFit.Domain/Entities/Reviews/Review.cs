using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Reviews;

public sealed class Review : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public int Rating { get; set; }
    public string? Title { get; set; }
    public string? Comment { get; set; }
    public Guid? GymId { get; set; }
    public Guid? GymBranchId { get; set; }
    public Guid? TrainerId { get; set; }
    public Guid? DoctorId { get; set; }
    public Guid? NutritionistId { get; set; }
    public Guid? ProductId { get; set; }
    public Guid? WorkoutProgramId { get; set; }
    public Guid? MealPlanId { get; set; }
    public bool IsApproved { get; set; }
    public bool IsVerifiedPurchase { get; set; }
}