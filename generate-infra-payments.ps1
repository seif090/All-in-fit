$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Payment options =====
Write-File "$base\Payments\PaymentOptions.cs" @'
using AllInFit.Shared.Contracts;

namespace AllInFit.Infrastructure.Payments;

public sealed class PaymentOptions
{
    public const string SectionName = "Payment";

    public PaymentGatewayProvider Provider { get; set; } = PaymentGatewayProvider.Stripe;
    public StripeOptions Stripe { get; set; } = new();
    public PaymobOptions Paymob { get; set; } = new();
    public FawryOptions Fawry { get; set; } = new();
    public WalletOptions Wallet { get; set; } = new();
}

public sealed class StripeOptions
{
    public string SecretKey { get; set; } = string.Empty;
    public string PublishableKey { get; set; } = string.Empty;
    public string WebhookSecret { get; set; } = string.Empty;
    public string Currency { get; set; } = "usd";
}

public sealed class PaymobOptions
{
    public string ApiKey { get; set; } = string.Empty;
    public int IntegrationId { get; set; }
    public int IframeId { get; set; }
    public string HmacSecret { get; set; } = string.Empty;
    public string Currency { get; set; } = "EGP";
}

public sealed class FawryOptions
{
    public string MerchantCode { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string BaseUrl { get; set; } = "https://www.atfawry.com/ECommerceWeb/Fawry/payments/charge";
    public string Currency { get; set; } = "EGP";
}

public sealed class WalletOptions
{
    public string Currency { get; set; } = "USD";
}
'@

# ===== Stripe payment gateway =====
Write-File "$base\Payments\StripePaymentGateway.cs" @'
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Stripe;
using Stripe.Checkout;

namespace AllInFit.Infrastructure.Payments;

/// <summary>
/// Stripe payment gateway via Charge and Checkout Sessions.
/// </summary>
public sealed class StripePaymentGateway : IPaymentGateway
{
    private readonly StripeOptions _options;
    private readonly ILogger<StripePaymentGateway> _logger;

    public StripePaymentGateway(IOptions<PaymentOptions> options, ILogger<StripePaymentGateway> logger)
    {
        _options = options.Value.Stripe;
        _logger = logger;
        StripeConfiguration.ApiKey = _options.SecretKey;
    }

    public async Task<PaymentResult> ProcessAsync(PaymentRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(request.ReturnUrl))
            {
                var sessionOptions = new SessionCreateOptions
                {
                    Mode = "payment",
                    LineItems = new List<SessionLineItemOptions>
                    {
                        new()
                        {
                            PriceData = new SessionLineItemPriceDataOptions
                            {
                                Currency = request.Currency?.ToLowerInvariant() ?? _options.Currency,
                                UnitAmount = (long)(request.Amount * 100),
                                ProductData = new SessionLineItemPriceDataProductDataOptions
                                {
                                    Name = request.Description ?? "All In Fit Payment"
                                }
                            },
                            Quantity = 1
                        }
                    },
                    SuccessUrl = request.ReturnUrl,
                    CancelUrl = request.CancelUrl ?? request.ReturnUrl,
                    Metadata = request.Metadata ?? new Dictionary<string, string>(),
                    CustomerEmail = request.CustomerEmail
                };

                var service = new SessionService();
                var session = await service.CreateAsync(sessionOptions, cancellationToken: cancellationToken);

                return new PaymentResult(true, session.Id, null, session.Url, "requires_action", null, null);
            }

            var chargeOptions = new ChargeCreateOptions
            {
                Amount = (long)(request.Amount * 100),
                Currency = request.Currency?.ToLowerInvariant() ?? _options.Currency,
                Description = request.Description,
                Metadata = request.Metadata ?? new Dictionary<string, string>()
            };

            if (!string.IsNullOrEmpty(request.CustomerEmail))
                chargeOptions.ReceiptEmail = request.CustomerEmail;

            var chargeService = new ChargeService();
            var charge = await chargeService.CreateAsync(chargeOptions, cancellationToken: cancellationToken);

            return new PaymentResult(
                charge.Paid,
                charge.Id,
                null,
                null,
                charge.Status,
                charge.Status == "failed" ? charge.FailureMessage : null,
                charge.Status == "failed" ? charge.FailureCode : null);
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe payment error for order {OrderId}", request.OrderId);
            return new PaymentResult(false, null, null, null, "failed", ex.Message, ex.StripeError?.Code);
        }
    }

    public Task<PaymentResult> RefundAsync(RefundRequest request, CancellationToken cancellationToken = default)
    {
        var options = new RefundCreateOptions
        {
            PaymentIntent = request.TransactionId,
            Amount = (long)(request.Amount * 100),
            Reason = RefundReasons.RequestedByCustomer,
            Metadata = request.Metadata ?? new Dictionary<string, string>()
        };

        var service = new RefundService();
        return service.CreateAsync(options, cancellationToken: cancellationToken)
            .ContinueWith(t =>
            {
                var refund = t.Result;
                return new PaymentResult(refund.Status is "succeeded" or "pending", refund.Id, null, null, refund.Status, null, null);
            }, cancellationToken);
    }

    public async Task<PaymentStatus> GetStatusAsync(string transactionId, CancellationToken cancellationToken = default)
    {
        var service = new PaymentIntentService();
        var intent = await service.GetAsync(transactionId, cancellationToken: cancellationToken);

        return new PaymentStatus(
            intent.Id,
            intent.Status,
            intent.Amount / 100m,
            intent.Currency?.ToUpperInvariant(),
            intent.Created,
            intent.LastPaymentError?.Message);
    }

    public Task<PaymentResult> VerifyWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default)
    {
        try
        {
            var stripeEvent = EventUtility.ConstructEvent(
                payload,
                signature,
                _options.WebhookSecret);

            _logger.LogInformation("Stripe webhook received: {Type}", stripeEvent.Type);

            // Handle specific event types
            switch (stripeEvent.Type)
            {
                case "checkout.session.completed":
                    var session = stripeEvent.Data.Object as Session;
                    return Task.FromResult(new PaymentResult(true, session?.Id, null, null, "succeeded", null, null));
                case "payment_intent.succeeded":
                    var intent = stripeEvent.Data.Object as PaymentIntent;
                    return Task.FromResult(new PaymentResult(true, intent?.Id, null, null, "succeeded", null, null));
                case "payment_intent.payment_failed":
                    var failed = stripeEvent.Data.Object as PaymentIntent;
                    return Task.FromResult(new PaymentResult(false, failed?.Id, null, null, "failed", failed?.LastPaymentError?.Message, failed?.LastPaymentError?.Code));
                case "charge.refunded":
                    var charge = stripeEvent.Data.Object as Charge;
                    return Task.FromResult(new PaymentResult(true, charge?.Id, null, null, "refunded", null, null));
            }

            return Task.FromResult(new PaymentResult(true, null, null, null, "ignored", null, null));
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe webhook signature verification failed");
            return Task.FromResult(new PaymentResult(false, null, null, null, "invalid_signature", ex.Message, ex.StripeError?.Code));
        }
    }
}
'@

# ===== Paymob payment gateway =====
Write-File "$base\Payments\PaymobPaymentGateway.cs" @'
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
'@

# ===== Fawry payment gateway =====
Write-File "$base\Payments\FawryPaymentGateway.cs" @'
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
'@

# ===== Wallet payment gateway (internal wallet) =====
Write-File "$base\Payments\WalletPaymentGateway.cs" @'
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
'@

Write-Host "Infrastructure payments layer generated successfully!"
