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