namespace AllInFit.Domain.Specifications;

/// <summary>
/// Evaluates specifications against IQueryable to produce the final query.
/// Domain-agnostic â€” does not depend on EF Core.
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
}