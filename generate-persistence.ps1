$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Persistence"
$domain = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Interceptors =====
Write-File "$base\Interceptors\AuditInterceptor.cs" @'
using AllInFit.Domain.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging;

namespace AllInFit.Persistence.Interceptors;

public sealed class AuditInterceptor : SaveChangesInterceptor
{
    private readonly ILogger<AuditInterceptor> _logger;

    public AuditInterceptor(ILogger<AuditInterceptor> logger)
    {
        _logger = logger;
    }

    public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
    {
        ApplyAudit(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(DbContextEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
    {
        ApplyAudit(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void ApplyAudit(DbContext? context)
    {
        if (context is null) return;

        var now = DateTime.UtcNow;
        var entries = context.ChangeTracker.Entries<AuditableEntity>();

        foreach (var entry in entries)
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedAt = now;
            }
            else if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = now;
            }
        }

        var softDeleteEntries = context.ChangeTracker.Entries<SoftDeleteEntity>();
        foreach (var entry in softDeleteEntries)
        {
            if (entry.State == EntityState.Deleted)
            {
                entry.State = EntityState.Modified;
                entry.Entity.IsDeleted = true;
                entry.Entity.DeletedAt = now;
            }
        }
    }
}
'@

Write-File "$base\Interceptors\DomainEventInterceptor.cs" @'
using AllInFit.Domain.Common;
using MediatR;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace AllInFit.Persistence.Interceptors;

public sealed class DomainEventInterceptor : SaveChangesInterceptor
{
    private readonly IPublisher _publisher;

    public DomainEventInterceptor(IPublisher publisher)
    {
        _publisher = publisher;
    }

    public override async ValueTask<int> SavedChangesAsync(SaveChangesCompletedEventData eventData, int result, CancellationToken cancellationToken = default)
    {
        if (eventData.Context is not null)
        {
            var entities = eventData.Context.ChangeTracker
                .Entries<BaseEntity>()
                .Where(e => e.Entity.DomainEvents.Count > 0)
                .Select(e => e.Entity)
                .ToList();

            foreach (var entity in entities)
            {
                foreach (var domainEvent in entity.DomainEvents.ToList())
                {
                    await _publisher.Publish(domainEvent, cancellationToken);
                    entity.ClearDomainEvents();
                }
            }
        }

        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }
}
'@

# ===== DbContext =====
Write-File "$base\Data\ApplicationDbContext.cs" @'
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Entities.Trainers;
using AllInFit.Domain.Entities.Doctors;
using AllInFit.Domain.Entities.Nutritionists;
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
    public DbSet<GymOwner> GymOwners => Set<GymOwner>();
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
    public DbSet<Domain.Entities.Wallet.Wallet> Wallets => Set<Domain.Entities.Wallet.Wallet>();
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
'@

# ===== Generic Repository =====
Write-File "$base\Repositories\IGenericRepository.cs" @'
using AllInFit.Domain.Specifications;

namespace AllInFit.Persistence.Repositories;

public interface IGenericRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<T?> GetBySpecificationAsync(ISpecification<T> spec, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetListBySpecificationAsync(ISpecification<T> spec, CancellationToken cancellationToken = default);
    Task<int> CountAsync(ISpecification<T> spec, CancellationToken cancellationToken = default);
    Task<bool> AnyAsync(ISpecification<T> spec, CancellationToken cancellationToken = default);
    Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);
    Task<T> UpdateAsync(T entity);
    Task DeleteAsync(T entity);
    Task DeleteRangeAsync(IEnumerable<T> entities);
    IQueryable<T> GetQuery();
}
'@

Write-File "$base\Repositories\GenericRepository.cs" @'
using AllInFit.Domain.Specifications;
using AllInFit.Persistence.Data;
using AllInFit.Persistence.Specifications;
using Microsoft.EntityFrameworkCore;

namespace AllInFit.Persistence.Repositories;

public sealed class GenericRepository<T> : IGenericRepository<T> where T : class
{
    private readonly ApplicationDbContext _context;
    private readonly DbSet<T> _dbSet;

    public GenericRepository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _dbSet.FindAsync([id], cancellationToken: cancellationToken);

    public async Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default)
        => await _dbSet.ToListAsync(cancellationToken);

    public async Task<T?> GetBySpecificationAsync(ISpecification<T> spec, CancellationToken cancellationToken = default)
        => await ApplySpecification(spec).FirstOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlyList<T>> GetListBySpecificationAsync(ISpecification<T> spec, CancellationToken cancellationToken = default)
        => await ApplySpecification(spec).ToListAsync(cancellationToken);

    public async Task<int> CountAsync(ISpecification<T> spec, CancellationToken cancellationToken = default)
        => await ApplySpecification(spec).CountAsync(cancellationToken);

    public async Task<bool> AnyAsync(ISpecification<T> spec, CancellationToken cancellationToken = default)
        => await ApplySpecification(spec).AnyAsync(cancellationToken);

    public async Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        var entry = await _dbSet.AddAsync(entity, cancellationToken);
        return entry.Entity;
    }

    public Task<T> UpdateAsync(T entity)
    {
        var entry = _dbSet.Update(entity);
        return Task.FromResult(entry.Entity);
    }

    public Task DeleteAsync(T entity)
    {
        _dbSet.Remove(entity);
        return Task.CompletedTask;
    }

    public Task DeleteRangeAsync(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
        return Task.CompletedTask;
    }

    public IQueryable<T> GetQuery() => _dbSet.AsQueryable();

    private IQueryable<T> ApplySpecification(ISpecification<T> spec)
        => PersistenceSpecificationEvaluator<T>.GetQuery(_dbSet.AsQueryable(), spec);
}
'@

# ===== Unit of Work =====
Write-File "$base\Repositories\IUnitOfWork.cs" @'
namespace AllInFit.Persistence.Repositories;

public interface IUnitOfWork : IDisposable
{
    IGenericRepository<T> Repository<T>() where T : class;
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
}
'@

Write-File "$base\Repositories\UnitOfWork.cs" @'
using AllInFit.Persistence.Data;
using Microsoft.EntityFrameworkCore.Storage;

namespace AllInFit.Persistence.Repositories;

public sealed class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private readonly Dictionary<Type, object> _repositories = new();
    private IDbContextTransaction? _transaction;
    private bool _disposed;

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
    }

    public IGenericRepository<T> Repository<T>() where T : class
    {
        var type = typeof(T);
        if (!_repositories.ContainsKey(type))
        {
            _repositories[type] = new GenericRepository<T>(_context);
        }
        return (IGenericRepository<T>)_repositories[type];
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => await _context.SaveChangesAsync(cancellationToken);

    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
        => _transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

    public async Task CommitTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction is not null)
            await _transaction.CommitAsync(cancellationToken);
    }

    public async Task RollbackTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction is not null)
            await _transaction.RollbackAsync(cancellationToken);
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            _transaction?.Dispose();
            _context.Dispose();
            _disposed = true;
        }
    }
}
'@

# ===== Persistence Specification Evaluator (with EF Core Includes) =====
Write-File "$base\Specifications\PersistenceSpecificationEvaluator.cs" @'
using AllInFit.Domain.Specifications;
using Microsoft.EntityFrameworkCore;

namespace AllInFit.Persistence.Specifications;

public static class PersistenceSpecificationEvaluator<T> where T : class
{
    public static IQueryable<T> GetQuery(IQueryable<T> inputQuery, ISpecification<T> specification)
    {
        var query = inputQuery;

        if (specification.Criteria is not null)
            query = query.Where(specification.Criteria);

        foreach (var include in specification.Includes)
            query = query.Include(include);

        foreach (var includeString in specification.IncludeStrings)
            query = query.Include(includeString);

        if (specification.IsDistinct)
            query = query.Distinct();

        if (specification.OrderBy is not null)
            query = query.OrderBy(specification.OrderBy);
        else if (specification.OrderByDescending is not null)
            query = query.OrderByDescending(specification.OrderByDescending);

        if (specification.IsPagingEnabled)
            query = query.Skip(specification.Skip).Take(specification.Take);

        return query;
    }
}
'@

# ===== DI Registration =====
Write-File "$base\DependencyInjection.cs" @'
using AllInFit.Persistence.Data;
using AllInFit.Persistence.Interceptors;
using AllInFit.Persistence.Repositories;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Persistence;

public static class DependencyInjection
{
    public static IServiceCollection AddPersistenceLayer(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

        services.AddScoped<AuditInterceptor>();
        services.AddScoped<DomainEventInterceptor>();

        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            var auditInterceptor = sp.GetRequiredService<AuditInterceptor>();
            var domainEventInterceptor = sp.GetRequiredService<DomainEventInterceptor>();

            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.CommandTimeout(120);
                sqlOptions.EnableRetryOnFailure(3);
                sqlOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
            })
            .AddInterceptors(auditInterceptor, domainEventInterceptor);
        });

        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        return services;
    }
}
'@

Write-Host "Persistence layer generated successfully!"
