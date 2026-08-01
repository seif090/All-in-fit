using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Wallet;

public sealed class Wallet : SoftDeleteEntity
{
    private readonly List<WalletTransaction> _transactions = new();

    public Guid UserId { get; set; }
    public decimal Balance { get; private set; }
    public string? Currency { get; set; } = "USD";
    public decimal RewardPointsBalance { get; private set; }
    public bool IsActive { get; set; } = true;

    public IReadOnlyCollection<WalletTransaction> Transactions => _transactions.AsReadOnly();

    public void Deposit(decimal amount, string description, string? reference = null)
    {
        Balance += amount;
        _transactions.Add(new WalletTransaction
        {
            WalletId = Id,
            Amount = amount,
            Type = WalletTransactionType.Deposit,
            Description = description,
            Reference = reference,
            BalanceAfter = Balance
        });
        UpdatedAt = DateTime.UtcNow;
    }

    public bool Withdraw(decimal amount, string description, string? reference = null)
    {
        if (amount > Balance) return false;
        Balance -= amount;
        _transactions.Add(new WalletTransaction
        {
            WalletId = Id,
            Amount = amount,
            Type = WalletTransactionType.Withdrawal,
            Description = description,
            Reference = reference,
            BalanceAfter = Balance
        });
        UpdatedAt = DateTime.UtcNow;
        return true;
    }

    public void AddRewardPoints(decimal points, string description)
    {
        RewardPointsBalance += points;
        UpdatedAt = DateTime.UtcNow;
    }

    public bool SpendRewardPoints(decimal points, string description)
    {
        if (points > RewardPointsBalance) return false;
        RewardPointsBalance -= points;
        UpdatedAt = DateTime.UtcNow;
        return true;
    }
}