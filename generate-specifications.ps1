$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Specification Pattern =====
Write-File "$base\Specifications\ISpecification.cs" @'
using System.Linq.Expressions;

namespace AllInFit.Domain.Specifications;

public interface ISpecification<T>
{
    Expression<Func<T, bool>>? Criteria { get; }
    List<Expression<Func<T, object>>> Includes { get; }
    List<string> IncludeStrings { get; }
    Expression<Func<T, object>>? OrderBy { get; }
    Expression<Func<T, object>>? OrderByDescending { get; }
    int Take { get; }
    int Skip { get; }
    bool IsPagingEnabled { get; }
    bool IsDistinct { get; }
}
'@

Write-File "$base\Specifications\BaseSpecification.cs" @'
using System.Linq.Expressions;

namespace AllInFit.Domain.Specifications;

public abstract class BaseSpecification<T> : ISpecification<T>
{
    public Expression<Func<T, bool>>? Criteria { get; private set; }
    public List<Expression<Func<T, object>>> Includes { get; } = new();
    public List<string> IncludeStrings { get; } = new();
    public Expression<Func<T, object>>? OrderBy { get; private set; }
    public Expression<Func<T, object>>? OrderByDescending { get; private set; }
    public int Take { get; private set; }
    public int Skip { get; private set; }
    public bool IsPagingEnabled { get; private set; }
    public bool IsDistinct { get; private set; }

    protected BaseSpecification(Expression<Func<T, bool>>? criteria = null)
    {
        Criteria = criteria;
    }

    protected void AddInclude(Expression<Func<T, object>> includeExpression) =>
        Includes.Add(includeExpression);

    protected void AddInclude(string includeString) =>
        IncludeStrings.Add(includeString);

    protected void ApplyOrderBy(Expression<Func<T, object>> orderByExpression) =>
        OrderBy = orderByExpression;

    protected void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescExpression) =>
        OrderByDescending = orderByDescExpression;

    protected void ApplyPaging(int skip, int take)
    {
        Skip = skip;
        Take = take;
        IsPagingEnabled = true;
    }

    protected void ApplyDistinct() => IsDistinct = true;
}
'@

Write-File "$base\Specifications\SpecificationEvaluator.cs" @'
namespace AllInFit.Domain.Specifications;

/// <summary>
/// Evaluates specifications against IQueryable to produce the final query.
/// </summary>
public static class SpecificationEvaluator<T>
{
    public static IQueryable<T> GetQuery(IQueryable<T> inputQuery, ISpecification<T> specification)
    {
        var query = inputQuery;

        if (specification.Criteria is not null)
            query = query.Where(specification.Criteria);

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

    public static IQueryable<T> GetQueryWithIncludes(IQueryable<T> inputQuery, ISpecification<T> specification)
    {
        var query = inputQuery;

        foreach (var include in specification.Includes)
            query = query.Include(include);

        foreach (var includeString in specification.IncludeStrings)
            query = query.Include(includeString);

        return query;
    }
}
'@

# ===== Example specifications =====
Write-File "$base\Specifications\UserSpecifications.cs" @'
using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class UserByEmailSpecification : BaseSpecification<User>
{
    public UserByEmailSpecification(string email) : base(u => u.Email.ToLower() == email.ToLower())
    {
        AddInclude(u => u.UserRoles);
        AddInclude("UserRoles.Role");
        AddInclude("UserRoles.Role.RolePermissions");
        AddInclude("UserRoles.Role.RolePermissions.Permission");
    }
}

public sealed class UserByIdSpecification : BaseSpecification<User>
{
    public UserByIdSpecification(Guid userId) : base(u => u.Id == userId)
    {
        AddInclude(u => u.UserRoles);
        AddInclude("UserRoles.Role");
        AddInclude("UserRoles.Role.RolePermissions");
        AddInclude("UserRoles.Role.RolePermissions.Permission");
        AddInclude(u => u.Devices);
    }
}

public sealed class ActiveUsersSpecification : BaseSpecification<User>
{
    public ActiveUsersSpecification() : base(u => u.IsActive && !u.IsDeleted)
    {
        ApplyOrderByDescending(u => u.CreatedAt);
    }
}
'@

Write-File "$base\Specifications\GymSpecifications.cs" @'
using AllInFit.Domain.Entities.Gyms;

namespace AllInFit.Domain.Specifications;

public sealed class GymsNearbySpecification : BaseSpecification<GymBranch>
{
    public GymsNearbySpecification(double latitude, double longitude, double radiusMeters)
        : base(b => b.IsActive && !b.IsDeleted)
    {
        ApplyOrderBy(b => b.Name);
    }
}

public sealed class GymByIdWithBranchesSpecification : BaseSpecification<Gym>
{
    public GymByIdWithBranchesSpecification(Guid gymId) : base(g => g.Id == gymId)
    {
        AddInclude(g => g.Branches);
    }
}
'@

Write-File "$base\Specifications\ProductSpecifications.cs" @'
using AllInFit.Domain.Entities.Marketplace;

namespace AllInFit.Domain.Specifications;

public sealed class AvailableProductsSpecification : BaseSpecification<Product>
{
    public AvailableProductsSpecification(string? searchTerm = null, Guid? categoryId = null, decimal? minPrice = null, decimal? maxPrice = null)
        : base(p =>
            p.IsAvailable &&
            !p.IsDeleted &&
            (string.IsNullOrWhiteSpace(searchTerm) || p.Name.Contains(searchTerm) || p.Description!.Contains(searchTerm)) &&
            (categoryId == null || p.CategoryId == categoryId) &&
            (minPrice == null || p.Price >= minPrice) &&
            (maxPrice == null || p.Price <= maxPrice))
    {
        ApplyOrderByDescending(p => p.CreatedAt);
    }
}

public sealed class ProductByIdSpecification : BaseSpecification<Product>
{
    public ProductByIdSpecification(Guid productId) : base(p => p.Id == productId && !p.IsDeleted)
    {
        AddInclude(p => p.Brand);
    }
}
'@

Write-Host "Specifications generated successfully!"
