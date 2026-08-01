$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Persistence"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# Simplified IUnitOfWork - just extends Application Ports
Write-File "$base\Repositories\IUnitOfWork.cs" @'
using AllInFit.Application.Ports;

namespace AllInFit.Persistence.Repositories;

public interface IUnitOfWork : Application.Ports.IUnitOfWork
{
}
'@

# Simplified IGenericRepository - just extends Application Ports
Write-File "$base\Repositories\IGenericRepository.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Specifications;

namespace AllInFit.Persistence.Repositories;

public interface IGenericRepository<T> : Application.Ports.IGenericRepository<T> where T : class
{
}
'@

# Simplified UnitOfWork - no explicit interface implementation
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

    public UnitOfWork(ApplicationDbContext context) => _context = context;

    public Application.Ports.IGenericRepository<T> Application.Ports.IUnitOfWork.Repository<T>() where T : class
        => Repository<T>();

    public IGenericRepository<T> Repository<T>() where T : class
    {
        var type = typeof(T);
        if (!_repositories.ContainsKey(type))
            _repositories[type] = new GenericRepository<T>(_context);
        return (IGenericRepository<T>)_repositories[type];
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => _context.SaveChangesAsync(cancellationToken);

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

# Simplified GenericRepository
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

# Fixed DependencyInjection - use fully qualified names
Write-File "$base\DependencyInjection.cs" @'
using AllInFit.Persistence.Data;
using AllInFit.Persistence.Interceptors;
using AllInFit.Persistence.Repositories;
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

        // Register concrete repositories
        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        // Register as Application.Ports for clean architecture
        services.AddScoped(typeof(AllInFit.Application.Ports.IGenericRepository<>), typeof(GenericRepository<>));
        // Register UnitOfWork as both interfaces
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<AllInFit.Application.Ports.IUnitOfWork>(sp => sp.GetRequiredService<IUnitOfWork>());

        return services;
    }
}
'@

Write-Host "Persistence simplified!"
