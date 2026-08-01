using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Comment : SoftDeleteEntity
{
    public Guid PostId { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public Guid? ParentCommentId { get; set; }
    public int LikeCount { get; set; }
    public Post? Post { get; set; }
}