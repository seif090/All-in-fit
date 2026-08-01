namespace AllInFit.Shared.Contracts;

/// <summary>
/// Abstraction for payment gateway providers (Stripe, Paymob, Fawry, Wallet).
/// </summary>
public interface IPaymentGateway
{
    Task<PaymentResult> ProcessAsync(PaymentRequest request, CancellationToken cancellationToken = default);
    Task<PaymentResult> RefundAsync(RefundRequest request, CancellationToken cancellationToken = default);
    Task<PaymentStatus> GetStatusAsync(string transactionId, CancellationToken cancellationToken = default);
    Task<PaymentResult> VerifyWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default);
}

public record PaymentRequest(
    decimal Amount,
    string Currency,
    string Description,
    string? OrderId,
    string? CustomerId,
    string? CustomerEmail,
    string? CustomerPhone,
    string? ReturnUrl,
    string? CancelUrl,
    string? PaymentMethod,
    Dictionary<string, string>? Metadata = null);

public record PaymentResult(
    bool Success,
    string? TransactionId,
    string? AuthorizationCode,
    string? RedirectUrl,
    string? Status,
    string? Error,
    string? ErrorCode);

public record RefundRequest(
    string TransactionId,
    decimal Amount,
    string Reason,
    Dictionary<string, string>? Metadata = null);

public record PaymentStatus(
    string TransactionId,
    string Status,
    decimal? Amount,
    string? Currency,
    DateTime? ProcessedAt,
    string? FailureReason);

public enum PaymentGatewayProvider
{
    Stripe,
    Paymob,
    Fawry,
    Wallet
}
