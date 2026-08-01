using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Professionals;

public sealed class TrainerCertificate : BaseEntity
{
    public Guid TrainerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? IssuedBy { get; set; }
    public DateTime IssuedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? CertificateUrl { get; set; }
    public string? VerificationCode { get; set; }
    public bool IsVerified { get; set; }
    public Trainer? Trainer { get; set; }
}