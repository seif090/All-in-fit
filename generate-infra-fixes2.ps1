$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"
$domain = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed: $path"
}

# ===== Fix CloudinaryFileStorage Bytes (non-nullable long) =====
$cloud = Get-Content "$base\Storage\CloudinaryFileStorage.cs" -Raw
$cloud = $cloud.Replace(
    'return new FileUploadResult(true, result.PublicId, result.SecureUrl?.ToString(), result.PublicId, result.Bytes?.Length, null);',
    'return new FileUploadResult(true, result.PublicId, result.SecureUrl?.ToString(), result.PublicId, result.Bytes, null);')
[System.IO.File]::WriteAllText("$base\Storage\CloudinaryFileStorage.cs", $cloud, [System.Text.Encoding]::UTF8)
Write-Host "Fixed: CloudinaryFileStorage Bytes"

# ===== Fix ProductSpecifications AddInclude nullability =====
Write-File "$domain\Specifications\ProductSpecifications.cs" @'
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
'@

Write-Host "Infrastructure fix batch 2 applied successfully!"
