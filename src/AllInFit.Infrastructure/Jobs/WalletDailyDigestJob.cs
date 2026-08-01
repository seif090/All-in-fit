using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Wallet;
using AllInFit.Domain.Specifications;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Produces a daily summary of all active wallet balances so finance
/// teams can reconcile system state with payment providers.
/// </summary>
public sealed class WalletDailyDigestJob
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<WalletDailyDigestJob> _logger;

    public WalletDailyDigestJob(IUnitOfWork unitOfWork, ILogger<WalletDailyDigestJob> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var repo = _unitOfWork.Repository<Wallet>();
        var wallets = await repo.GetListBySpecificationAsync(new ActiveWalletsSpecification(), cancellationToken);

        var totalBalance = wallets.Sum(w => w.Balance);
        var totalRewardPoints = wallets.Sum(w => w.RewardPointsBalance);

        _logger.LogInformation(
            "WalletDailyDigestJob: {WalletCount} active wallets, total balance {TotalBalance}, total reward points {TotalRewardPoints}",
            wallets.Count, totalBalance, totalRewardPoints);
    }
}

internal sealed class ActiveWalletsSpecification : BaseSpecification<Wallet>
{
    public ActiveWalletsSpecification()
        : base(w => w.IsActive)
    {
    }
}