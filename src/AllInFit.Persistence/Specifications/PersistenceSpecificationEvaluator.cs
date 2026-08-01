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