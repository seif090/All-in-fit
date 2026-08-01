using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class Achievement : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public int RewardPoints { get; set; }
    public string? Criteria { get; set; }
}