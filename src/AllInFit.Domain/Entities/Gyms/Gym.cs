using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gyms;

public sealed class Gym : SoftDeleteEntity
{
    private readonly List<GymBranch> _branches = new();

    private Gym() { }

    public Gym(string name, string legalName, string? logoUrl, string? description, string? website, Guid ownerUserId)
    {
        Name = name;
        LegalName = legalName;
        LogoUrl = logoUrl;
        Description = description;
        Website = website;
        OwnerUserId = ownerUserId;
        IsVerified = false;
        IsActive = true;
    }

    public string Name { get; private set; } = string.Empty;
    public string LegalName { get; private set; } = string.Empty;
    public string? LogoUrl { get; private set; }
    public string? Description { get; private set; }
    public string? Website { get; private set; }
    public Guid OwnerUserId { get; private set; }
    public bool IsVerified { get; private set; }
    public bool IsActive { get; private set; }
    public double? Rating { get; private set; }
    public int ReviewCount { get; private set; }
    public Guid? PrimaryBranchId { get; private set; }

    public IReadOnlyCollection<GymBranch> Branches => _branches.AsReadOnly();

    public void AddBranch(GymBranch branch) => _branches.Add(branch);
    public void Verify() { IsVerified = true; UpdatedAt = DateTime.UtcNow; }
    public void Deactivate() { IsActive = false; UpdatedAt = DateTime.UtcNow; }
    public void UpdateRating(double rating, int count) { Rating = rating; ReviewCount = count; UpdatedAt = DateTime.UtcNow; }
}