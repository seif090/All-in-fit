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