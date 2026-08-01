using AllInFit.Domain.Entities.Marketplace;

namespace AllInFit.Domain.Specifications;

public sealed class AvailableProductsSpecification : BaseSpecification<Product>
{
    public AvailableProductsSpecification(string? searchTerm = null, Guid? categoryId = null, decimal? minPrice = null, decimal? maxPrice = null)
        : base(p =>
            p.IsAvailable &&
            !p.IsDeleted &&
            (string.IsNullOrWhiteSpace(searchTerm) ||
             p.Name.Contains(searchTerm!) ||
             (searchTerm != null && !string.IsNullOrEmpty(p.Description) && p.Description.Contains(searchTerm))) &&
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
        AddInclude(nameof(Product.Brand));
    }
}