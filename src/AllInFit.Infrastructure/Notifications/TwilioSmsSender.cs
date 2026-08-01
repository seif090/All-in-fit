using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Twilio;
using Twilio.Rest.Api.V2010.Account;

namespace AllInFit.Infrastructure.Notifications;

/// <summary>
/// SMS sender built on Twilio.
/// </summary>
public sealed class TwilioSmsSender : ISmsSender
{
    private readonly SmsOptions _options;
    private readonly ILogger<TwilioSmsSender> _logger;

    public TwilioSmsSender(IOptions<SmsOptions> options, ILogger<TwilioSmsSender> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(SmsMessage message, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(message);

        if (!_options.Enabled)
        {
            _logger.LogInformation("[SmsDisabled] Would send to {To}: {Text}", message.PhoneNumber, message.Text);
            return;
        }

        try
        {
            TwilioClient.Init(_options.AccountSid, _options.AuthToken);

            var msg = await MessageResource.CreateAsync(
                body: message.Text,
                from: new Twilio.Types.PhoneNumber(message.SenderId ?? _options.FromNumber),
                to: new Twilio.Types.PhoneNumber(message.PhoneNumber));

            _logger.LogInformation("SMS sent to {To} (sid {Sid})", message.PhoneNumber, msg.Sid);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send SMS to {To}", message.PhoneNumber);
            throw;
        }
    }
}