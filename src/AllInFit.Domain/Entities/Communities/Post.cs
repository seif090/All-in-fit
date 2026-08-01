using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Post : SoftDeleteEntity
{
    public Guid CommunityId { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int LikeCount { get; set; }
    public int CommentCount { get; set; }
    public bool IsPinned { get; set; }
    public Community? Community { get; set; }
}