using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Entities.Professionals;
using AllInFit.Domain.Entities.Workouts;
using AllInFit.Domain.Entities.Nutrition;
using AllInFit.Domain.Entities.Marketplace;
using AllInFit.Domain.Entities.Wallet;
using AllInFit.Domain.Entities.Appointments;
using AllInFit.Domain.Entities.Reviews;
using AllInFit.Domain.Entities.Notifications;
using AllInFit.Domain.Entities.Chat;
using AllInFit.Domain.Entities.Communities;
using AllInFit.Domain.Entities.Gamification;
using AllInFit.Domain.Entities.Referrals;
using AllInFit.Domain.Entities.Crm;
using AllInFit.Domain.Entities.Cms;
using AllInFit.Domain.Entities.Files;
using AllInFit.Domain.Common;
using Microsoft.EntityFrameworkCore;

namespace AllInFit.Persistence.Data;

public sealed class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    // Identity
    public DbSet<User> Users => Set<User>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<UserSession> UserSessions => Set<UserSession>();

    // Gyms
    public DbSet<Gym> Gyms => Set<Gym>();
    public DbSet<GymBranch> GymBranches => Set<GymBranch>();
    public DbSet<GymMembership> GymMemberships => Set<GymMembership>();
    public DbSet<GymSchedule> GymSchedules => Set<GymSchedule>();

    // Fitness Professionals
    public DbSet<Trainer> Trainers => Set<Trainer>();
    public DbSet<TrainerCertificate> TrainerCertificates => Set<TrainerCertificate>();
    public DbSet<TrainerAvailability> TrainerAvailabilities => Set<TrainerAvailability>();
    public DbSet<Doctor> Doctors => Set<Doctor>();
    public DbSet<DoctorSpecialty> DoctorSpecialties => Set<DoctorSpecialty>();
    public DbSet<Nutritionist> Nutritionists => Set<Nutritionist>();

    // Workouts
    public DbSet<WorkoutProgram> WorkoutPrograms => Set<WorkoutProgram>();
    public DbSet<WorkoutCategory> WorkoutCategories => Set<WorkoutCategory>();
    public DbSet<Exercise> Exercises => Set<Exercise>();
    public DbSet<WorkoutProgramExercise> WorkoutProgramExercises => Set<WorkoutProgramExercise>();

    // Nutrition
    public DbSet<MealPlan> MealPlans => Set<MealPlan>();
    public DbSet<Recipe> Recipes => Set<Recipe>();

    // Marketplace
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Coupon> Coupons => Set<Coupon>();

    // Wallet
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();

    // Appointments
    public DbSet<Appointment> Appointments => Set<Appointment>();

    // Reviews
    public DbSet<Review> Reviews => Set<Review>();

    // Notifications
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationTemplate> NotificationTemplates => Set<NotificationTemplate>();

    // Chat
    public DbSet<ChatConversation> ChatConversations => Set<ChatConversation>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();

    // Communities
    public DbSet<Community> Communities => Set<Community>();
    public DbSet<CommunityMember> CommunityMembers => Set<CommunityMember>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<Like> Likes => Set<Like>();

    // Gamification
    public DbSet<Challenge> Challenges => Set<Challenge>();
    public DbSet<ChallengeParticipant> ChallengeParticipants => Set<ChallengeParticipant>();
    public DbSet<LeaderboardEntry> LeaderboardEntries => Set<LeaderboardEntry>();
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();
    public DbSet<Badge> Badges => Set<Badge>();
    public DbSet<UserBadge> UserBadges => Set<UserBadge>();

    // Referrals
    public DbSet<Referral> Referrals => Set<Referral>();

    // CRM
    public DbSet<CrmCustomer> CrmCustomers => Set<CrmCustomer>();

    // CMS
    public DbSet<CmsContent> CmsContents => Set<CmsContent>();
    public DbSet<Setting> Settings => Set<Setting>();

    // Files
    public DbSet<StoredFile> StoredFiles => Set<StoredFile>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);

        // Global query filters for soft delete
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            if (typeof(SoftDeleteEntity).IsAssignableFrom(entityType.ClrType))
            {
                var method = typeof(ApplicationDbContext)
                    .GetMethod(nameof(SetSoftDeleteFilter), System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static)!
                    .MakeGenericMethod(entityType.ClrType);
                method.Invoke(null, new object[] { modelBuilder });
            }
        }
    }

    private static void SetSoftDeleteFilter<TEntity>(ModelBuilder modelBuilder) where TEntity : SoftDeleteEntity
    {
        modelBuilder.Entity<TEntity>().HasQueryFilter(e => !e.IsDeleted);
    }
}