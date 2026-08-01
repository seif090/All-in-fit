using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Cms;

public sealed class Setting : BaseEntity
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Type { get; set; }
    public bool IsPublic { get; set; }
}