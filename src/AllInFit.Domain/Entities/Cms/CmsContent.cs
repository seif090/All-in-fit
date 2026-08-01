using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Cms;

public sealed class CmsContent : SoftDeleteEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Slug { get; set; }
    public string? Content { get; set; }
    public string? Summary { get; set; }
    public string? CoverImageUrl { get; set; }
    public string? Category { get; set; }
    public string[]? Tags { get; set; }
    public bool IsPublished { get; set; }
    public DateTime? PublishedAt { get; set; }
    public string? Author { get; set; }
    public int ViewCount { get; set; }
}