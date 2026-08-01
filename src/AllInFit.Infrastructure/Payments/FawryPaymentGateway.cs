using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Payments;

/// <summary>
/// Fawry payment gateway (Egypt). Supports card and wallet charge with signed requests.
/// </summary>
public sealed class FawryPaymentGateway : IPaymentGateway
{
    private readonly FawryOptions _options;
    private readonly ILogger<FawryPaymentGateway> _logger;
    private readonly HttpClient _http;

    public FawryPaymentGateway(IOptions<PaymentOptions> options, ILogger<FawryPaymentGateway> logger, IHttpClientFactory httpFactory)
    {
        _options = options.Value.Fawry;
        _logger = logger;
        _http = httpFactory.CreateClient("Fawry");
    }

    public async Task<PaymentResult> ProcessAsync(PaymentRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var merchantRefNum = $"{request.OrderId}-{Guid.NewGuid():N}"[..Math.Min(50, $"{request.OrderId}-{Guid.NewGuid():N}".Length)];
            var signature = ComputeSignature(
                _options.MerchantCode,
                merchantRefNum,
                request.Amount,
                request.Currency ?? _options.Currency,
                request.Description ?? string.Empty);

            var payload = new
            {
                merchantCode = _options.MerchantCode,
                merchantRefNum,
                customerMobile = request.CustomerPhone?.Replace("+", "") ?? string.Empty,
                customerEmail = request.CustomerEmail ?? string.Empty,
                amount = request.Amount,
                currencyCode = request.Currency ?? _options.Currency,
                description = request.Description,
                paymentMethod = request.PaymentMethod ?? "PAYWITHCARD",
                signature
            };

            var response = await _http.PostAsJsonAsync(_options.BaseUrl, payload, cancellationToken);
            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            using var json = JsonDocument.Parse(content);

            var statusCode = json.RootElement.GetProperty("statusCode").GetInt32();
            var statusDescription = json.RootElement.GetProperty("statusDescription").GetString();

            return new PaymentResult(
                statusCode == 200,
                merchantRefNum,
                null,
                json.RootElement.TryGetProperty("paymentUrl", out var url) ? url.GetString() : null,
                statusCode == 200 ? "pending" : "failed",
                statusCode == 200 ? null : statusDescription,
                statusCode == 200 ? null : statusCode.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fawry payment error for order {OrderId}", request.OrderId);
            return new PaymentResult(false, null, null, null, "failed", ex.Message, "FAWRY_ERROR");
        }
    }

    public Task<PaymentResult> RefundAsync(RefundRequest request, CancellationToken cancellationToken = default)
    {
        // Fawry refund requires a call to refund endpoint with signed payload
        _logger.LogWarning("Fawry refund requested for {TransactionId}. Implement refund endpoint integration.", request.TransactionId);
        return Task.FromResult(new PaymentResult(false, null, null, null, "unsupported", "Fawry refund requires endpoint configuration", "FAWRY_REFUND"));
    }

    public Task<PaymentStatus> GetStatusAsync(string transactionId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Fawry status lookup for {TransactionId}", transactionId);
        return Task.FromResult(new PaymentStatus(transactionId, "unknown", null, null, null, null));
    }

    public Task<PaymentResult> VerifyWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default)
    {
        try
        {
            using var json = JsonDocument.Parse(payload);
            var root = json.RootElement;

            var merchantRef = root.GetProperty("merchantRefNum").GetString();
            var amount = root.GetProperty("paymentAmount").GetDecimal();
            var orderStatus = root.GetProperty("orderStatus").GetString();

            var message = $"{_options.MerchantCode}{merchantRef}{amount:F2}{orderStatus}";
            var computedSignature = ComputeHmac(message);

            if (!string.Equals(computedSignature, signature, StringComparison.OrdinalIgnoreCase))
            {
                return Task.FromResult(new PaymentResult(false, null, null, null, "invalid_signature", "HMAC verification failed", null));
            }

            return Task.FromResult(new PaymentResult(
                orderStatus == "PAID",
                merchantRef,
                null,
                null,
                orderStatus == "PAID" ? "succeeded" : orderStatus?.ToLowerInvariant(),
                null,
                null));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fawry webhook processing failed");
            return Task.FromResult(new PaymentResult(false, null, null, null, "error", ex.Message, "FAWRY_WEBHOOK"));
        }
    }

    private string ComputeSignature(string merchantCode, string merchantRefNum, decimal amount, string currency, string description)
    {
        var message = $"{merchantCode}{merchantRefNum}{amount:F2}{currency}{description}";
        return ComputeHmac(message);
    }

    private string ComputeHmac(string message)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_options.SecretKey));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(message));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}