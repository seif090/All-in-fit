using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Wallet;

public sealed class WalletTransaction : BaseEntity
{
    public Guid WalletId { get; set; }
    public decimal Amount { get; set; }
    public WalletTransactionType Type { get; set; }
    public string? Description { get; set; }
    public string? Reference { get; set; }
    public decimal BalanceAfter { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Wallet? Wallet { get; set; }
}