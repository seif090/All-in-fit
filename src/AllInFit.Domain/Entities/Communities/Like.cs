using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Like : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid? PostId { get; set; }
    public Guid? CommentId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Post? Post { get; set; }
    public Comment? Comment { get; set; }
}