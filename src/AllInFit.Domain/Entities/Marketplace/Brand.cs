using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Marketplace;

public sealed class Brand : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsVerified { get; set; }
}