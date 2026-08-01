using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class CommunityMember : BaseEntity
{
    public Guid CommunityId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "Member";
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public Community? Community { get; set; }
}