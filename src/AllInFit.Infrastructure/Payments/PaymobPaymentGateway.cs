using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Payments;

/// <summary>
/// Paymob payment gateway (Middle East / Egypt). Uses IFrame for hosted checkout.
/// </summary>
public sealed class PaymobPaymentGateway : IPaymentGateway
{
    private readonly PaymobOptions _options;
    private readonly ILogger<PaymobPaymentGateway> _logger;
    private readonly HttpClient _http;

    private const string AuthUrl = "https://accept.paymob.com/api/auth/tokens";
    private const string OrderUrl = "https://accept.paymob.com/api/ecommerce/orders";
    private const string PaymentKeyUrl = "https://accept.paymob.com/api/acceptance/payment_keys";

    public PaymobPaymentGateway(IOptions<PaymentOptions> options, ILogger<PaymobPaymentGateway> logger, IHttpClientFactory httpFactory)
    {
        _options = options.Value.Paymob;
        _logger = logger;
        _http = httpFactory.CreateClient("Paymob");
    }

    public async Task<PaymentResult> ProcessAsync(PaymentRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // 1. Auth token
            var authResponse = await _http.PostAsJsonAsync(AuthUrl, new { api_key = _options.ApiKey }, cancellationToken);
            authResponse.EnsureSuccessStatusCode();
            var auth = await authResponse.Content.ReadFromJsonAsync<PaymobAuthResponse>(cancellationToken: cancellationToken);
            var token = auth?.Token;

            // 2. Create order
            var orderPayload = new
            {
                auth_token = token,
                delivery_needed = "false",
                amount_cents = (int)(request.Amount * 100),
                currency = request.Currency ?? _options.Currency,
                items = new[] { new { name = request.Description, amount_cents = (int)(request.Amount * 100), quantity = 1 } }
            };

            var orderResponse = await _http.PostAsJsonAsync(OrderUrl, orderPayload, cancellationToken);
            orderResponse.EnsureSuccessStatusCode();
            var order = await orderResponse.Content.ReadFromJsonAsync<PaymobOrderResponse>(cancellationToken: cancellationToken);

            // 3. Payment key for IFrame
            var paymentKeyPayload = new
            {
                auth_token = token,
                amount_cents = (int)(request.Amount * 100),
                expiration = 3600,
                order_id = order?.Id,
                billing_data = new
                {
                    apartment = "NA",
                    email = request.CustomerEmail ?? "customer@example.com",
                    floor = "NA",
                    first_name = "AllInFit",
                    street = "NA",
                    building = "NA",
                    phone_number = request.CustomerPhone ?? "+0000000000",
                    shipping_method = "PKG",
                    postal_code = "NA",
                    city = "NA",
                    country = "EG",
                    last_name = "Customer",
                    state = "NA"
                },
                currency = request.Currency ?? _options.Currency,
                integration_id = _options.IntegrationId
            };

            var pkResponse = await _http.PostAsJsonAsync(PaymentKeyUrl, paymentKeyPayload, cancellationToken);
            pkResponse.EnsureSuccessStatusCode();
            var pk = await pkResponse.Content.ReadFromJsonAsync<PaymobPaymentKeyResponse>(cancellationToken: cancellationToken);

            var iframeUrl = $"https://accept.paymob.com/api/acceptance/iframes/{_options.IframeId}?payment_token={pk?.PaymentKey}";

            return new PaymentResult(true, pk?.PaymentKey, null, iframeUrl, "pending", null, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Paymob payment error for order {OrderId}", request.OrderId);
            return new PaymentResult(false, null, null, null, "failed", ex.Message, "PAYMOB_ERROR");
        }
    }

    public Task<PaymentResult> RefundAsync(RefundRequest request, CancellationToken cancellationToken = default)
    {
        // Paymob refund via API requires transaction id and amount
        _logger.LogWarning("Paymob refund requested for {TransactionId}. Requires manual/HRM validation.", request.TransactionId);
        return Task.FromResult(new PaymentResult(false, null, null, null, "unsupported", "Paymob refund processing requires dashboard setup", "PAYMOB_REFUND"));
    }

    public Task<PaymentStatus> GetStatusAsync(string transactionId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Paymob status lookup for {TransactionId}", transactionId);
        return Task.FromResult(new PaymentStatus(transactionId, "unknown", null, null, null, null));
    }

    public Task<PaymentResult> VerifyWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default)
    {
        // HMAC verification using HmacSecret
        using var hmac = new System.Security.Cryptography.HMACSHA512(Encoding.UTF8.GetBytes(_options.HmacSecret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        var computed = Convert.ToHexString(hash).ToLowerInvariant();

        if (computed != signature?.ToLowerInvariant())
        {
            _logger.LogWarning("Paymob webhook signature mismatch");
            return Task.FromResult(new PaymentResult(false, null, null, null, "invalid_signature", "HMAC verification failed", null));
        }

        using var json = JsonDocument.Parse(payload);
        var status = json.RootElement.GetProperty("obj").GetProperty("success").GetString();

        return Task.FromResult(new PaymentResult(
            status == "true",
            json.RootElement.TryGetProperty("obj", out var obj) && obj.TryGetProperty("id", out var id) ? id.GetInt32().ToString() : null,
            null,
            null,
            status == "true" ? "succeeded" : "failed",
            null,
            null));
    }

    private sealed class PaymobAuthResponse
    {
        [JsonPropertyName("token")] public string? Token { get; set; }
    }

    private sealed class PaymobOrderResponse
    {
        [JsonPropertyName("id")] public int Id { get; set; }
    }

    private sealed class PaymobPaymentKeyResponse
    {
        [JsonPropertyName("token")] public string? PaymentKey { get; set; }
    }
}