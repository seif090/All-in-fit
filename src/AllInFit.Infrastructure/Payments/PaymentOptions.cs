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