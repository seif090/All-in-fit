using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Community : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }
    public bool IsPrivate { get; set; }
    public bool IsActive { get; set; } = true;
    public Guid? CreatedByUserId { get; set; }
    public int MemberCount { get; set; }
    public int PostCount { get; set; }
}