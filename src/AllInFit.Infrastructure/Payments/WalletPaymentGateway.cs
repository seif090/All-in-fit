using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Payments;

/// <summary>
/// Internal wallet payment gateway. Validates the user's wallet has sufficient balance
/// (business logic handled in the Application layer); records a ledger transaction.
/// </summary>
public sealed class WalletPaymentGateway : IPaymentGateway
{
    private readonly WalletOptions _options;
    private readonly ILogger<WalletPaymentGateway> _logger;

    public WalletPaymentGateway(IOptions<PaymentOptions> options, ILogger<WalletPaymentGateway> logger)
    {
        _options = options.Value.Wallet;
        _logger = logger;
    }

    public Task<PaymentResult> ProcessAsync(PaymentRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
        {
            return Task.FromResult(new PaymentResult(false, null, null, null, "failed", "Amount must be positive", "INVALID_AMOUNT"));
        }

        // Application layer handles ledger mutation and concurrency.
        var transactionId = $"WLT_{Guid.NewGuid():N}";
        _logger.LogInformation("Wallet payment initiated {TransactionId} for order {OrderId}", transactionId, request.OrderId);

        return Task.FromResult(new PaymentResult(true, transactionId, null, null, "succeeded", null, null));
    }

    public Task<PaymentResult> RefundAsync(RefundRequest request, CancellationToken cancellationToken = default)
    {
        var transactionId = $"WLT_REF_{Guid.NewGuid():N}";
        _logger.LogInformation("Wallet refund initiated {TransactionId} for {OriginalTransactionId}", transactionId, request.TransactionId);
        return Task.FromResult(new PaymentResult(true, transactionId, null, null, "succeeded", null, null));
    }

    public Task<PaymentStatus> GetStatusAsync(string transactionId, CancellationToken cancellationToken = default)
        => Task.FromResult(new PaymentStatus(transactionId, "succeeded", null, _options.Currency, null, null));

    public Task<PaymentResult> VerifyWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default)
        => Task.FromResult(new PaymentResult(true, null, null, null, "ignored", null, null));
}