$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Workout aggregates =====
Write-File "$base\Entities\Workouts\WorkoutCategory.cs" @'
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
'@

Write-File "$base\Entities\Workouts\Exercise.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Workouts;

public sealed class Exercise : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Instructions { get; set; }
    public string? VideoUrl { get; set; }
    public string? ImageUrl { get; set; }
    public string? MuscleGroup { get; set; }
    public string? Equipment { get; set; }
    public DifficultyLevel DifficultyLevel { get; set; }
    public bool IsCompound { get; set; }
    public int? EstimatedCaloriesBurned { get; set; }
    public bool IsActive { get; set; } = true;
}
'@

Write-File "$base\Entities\Workouts\WorkoutProgram.cs" @'
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
'@

Write-File "$base\Entities\Workouts\WorkoutProgramExercise.cs" @'
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
'@

# ===== Nutrition aggregates =====
Write-File "$base\Entities\Nutrition\Recipe.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Nutrition;

public sealed class Recipe : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Ingredients { get; set; }
    public string? Instructions { get; set; }
    public MealType MealType { get; set; }
    public int Calories { get; set; }
    public int ProteinGrams { get; set; }
    public int CarbsGrams { get; set; }
    public int FatGrams { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsVegetarian { get; set; }
    public bool IsVegan { get; set; }
    public bool IsGlutenFree { get; set; }
    public bool IsPublished { get; set; }
    public Guid? CreatedByUserId { get; set; }
}
'@

Write-File "$base\Entities\Nutrition\MealPlan.cs" @'
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
'@

# ===== Marketplace aggregates =====
Write-File "$base\Entities\Marketplace\Brand.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Brand : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsVerified { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\Product.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Product : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Sku { get; set; } = string.Empty;
    public Guid? BrandId { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public string? Currency { get; set; } = "USD";
    public int StockQuantity { get; set; }
    public bool IsAvailable { get; set; } = true;
    public string? ImageUrl { get; set; }
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public bool IsSupplement { get; set; }
    public bool RequiresPrescription { get; set; }
    public Brand? Brand { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\ProductCategory.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class ProductCategory : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int SortOrder { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\CartItem.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class CartItem : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
    public Product? Product { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\WishlistItem.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class WishlistItem : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid ProductId { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
    public Product? Product { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\Order.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Order : SoftDeleteEntity
{
    private readonly List<OrderItem> _items = new();

    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public OrderStatus Status { get; set; }
    public decimal Subtotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal ShippingAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string? Currency { get; set; } = "USD";
    public string? ShippingAddress { get; set; }
    public string? BillingAddress { get; set; }
    public Guid? CouponId { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? ShippedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime? CancelledAt { get; set; }

    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();
    public void AddItem(OrderItem item) => _items.Add(item);
}
'@

Write-File "$base\Entities\Marketplace\OrderItem.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal LineTotal { get; set; }
    public Order? Order { get; set; }
    public Product? Product { get; set; }
}
'@

Write-File "$base\Entities\Marketplace\Coupon.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Coupon : SoftDeleteEntity
{
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal? DiscountPercent { get; set; }
    public decimal? MinOrderAmount { get; set; }
    public DateTime? ValidFrom { get; set; }
    public DateTime? ValidTo { get; set; }
    public int? MaxUses { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; } = true;

    public bool IsValid =>
        IsActive &&
        (ValidFrom == null || ValidFrom <= DateTime.UtcNow) &&
        (ValidTo == null || ValidTo >= DateTime.UtcNow) &&
        (MaxUses == null || UsedCount < MaxUses);
}
'@

# ===== Wallet aggregates =====
Write-File "$base\Entities\Wallet\Wallet.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Wallet;

public sealed class Wallet : SoftDeleteEntity
{
    private readonly List<WalletTransaction> _transactions = new();

    public Guid UserId { get; set; }
    public decimal Balance { get; private set; }
    public string? Currency { get; set; } = "USD";
    public decimal RewardPointsBalance { get; private set; }
    public bool IsActive { get; set; } = true;

    public IReadOnlyCollection<WalletTransaction> Transactions => _transactions.AsReadOnly();

    public void Deposit(decimal amount, string description, string? reference = null)
    {
        Balance += amount;
        _transactions.Add(new WalletTransaction
        {
            WalletId = Id,
            Amount = amount,
            Type = WalletTransactionType.Deposit,
            Description = description,
            Reference = reference,
            BalanceAfter = Balance
        });
        UpdatedAt = DateTime.UtcNow;
    }

    public bool Withdraw(decimal amount, string description, string? reference = null)
    {
        if (amount > Balance) return false;
        Balance -= amount;
        _transactions.Add(new WalletTransaction
        {
            WalletId = Id,
            Amount = amount,
            Type = WalletTransactionType.Withdrawal,
            Description = description,
            Reference = reference,
            BalanceAfter = Balance
        });
        UpdatedAt = DateTime.UtcNow;
        return true;
    }

    public void AddRewardPoints(decimal points, string description)
    {
        RewardPointsBalance += points;
        UpdatedAt = DateTime.UtcNow;
    }

    public bool SpendRewardPoints(decimal points, string description)
    {
        if (points > RewardPointsBalance) return false;
        RewardPointsBalance -= points;
        UpdatedAt = DateTime.UtcNow;
        return true;
    }
}
'@

Write-File "$base\Entities\Wallet\WalletTransaction.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Wallet;

public sealed class WalletTransaction : BaseEntity
{
    public Guid WalletId { get; set; }
    public decimal Amount { get; set; }
    public WalletTransactionType Type { get; set; }
    public string? Description { get; set; }
    public string? Reference { get; set; }
    public decimal BalanceAfter { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Wallet? Wallet { get; set; }
}
'@

# ===== Appointments =====
Write-File "$base\Entities\Appointments\Appointment.cs" @'
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
'@

Write-Host "Domain layer part 3 generated successfully!"
