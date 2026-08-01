$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Email options =====
Write-File "$base\Notifications\EmailOptions.cs" @'
namespace AllInFit.Infrastructure.Notifications;

public sealed class EmailOptions
{
    public const string SectionName = "Email";

    public bool Enabled { get; set; }
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 587;
    public bool UseSsl { get; set; } = true;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string From { get; set; } = "noreply@allinfit.com";
    public string FromName { get; set; } = "All In Fit";
}
'@

# ===== Email sender (MailKit / SMTP) =====
Write-File "$base\Notifications\SmtpEmailSender.cs" @'
using AllInFit.Shared.Contracts;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace AllInFit.Infrastructure.Notifications;

/// <summary>
/// SMTP email sender built on MailKit. Supports HTML bodies, attachments, CC/BCC.
/// </summary>
public sealed class SmtpEmailSender : IEmailSender
{
    private readonly EmailOptions _options;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IOptions<EmailOptions> options, ILogger<SmtpEmailSender> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(message);

        if (!_options.Enabled)
        {
            _logger.LogInformation("[EmailDisabled] Would send to {To}: {Subject}", message.To, message.Subject);
            return;
        }

        var mime = new MimeMessage
        {
            Subject = message.Subject,
            Body = new BodyBuilder
            {
                HtmlBody = message.IsHtml ? message.Body : null,
                TextBody = message.IsHtml ? null : message.Body
            }.ToMessageBody()
        };

        mime.From.Add(new MailboxAddress(_options.FromName, message.From ?? _options.From));
        mime.To.Add(MailboxAddress.Parse(message.To));

        if (!string.IsNullOrWhiteSpace(message.ReplyTo))
            mime.ReplyTo.Add(MailboxAddress.Parse(message.ReplyTo));

        foreach (var cc in message.Cc ?? [])
            mime.Cc.Add(MailboxAddress.Parse(cc));
        foreach (var bcc in message.Bcc ?? [])
            mime.Bcc.Add(MailboxAddress.Parse(bcc));

        if (message.Attachments is not null)
        {
            var builder = (BodyBuilder)mime.Body;
            foreach (var attachment in message.Attachments)
            {
                builder.Attachments.Add(attachment.FileName, attachment.Content, ContentType.Parse(attachment.ContentType));
            }
            mime.Body = builder.ToMessageBody();
        }

        try
        {
            using var client = new SmtpClient();
            await client.ConnectAsync(_options.Host, _options.Port, _options.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.Auto, cancellationToken);

            if (!string.IsNullOrEmpty(_options.UserName))
                await client.AuthenticateAsync(_options.UserName, _options.Password, cancellationToken);

            await client.SendAsync(mime, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation("Email sent to {To} with subject {Subject}", message.To, message.Subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {To}", message.To);
            throw;
        }
    }
}
'@

# ===== SMS options =====
Write-File "$base\Notifications\SmsOptions.cs" @'
namespace AllInFit.Infrastructure.Notifications;

public sealed class SmsOptions
{
    public const string SectionName = "Sms";

    public bool Enabled { get; set; }
    public string Provider { get; set; } = "Twilio";
    public string AccountSid { get; set; } = string.Empty;
    public string AuthToken { get; set; } = string.Empty;
    public string FromNumber { get; set; } = string.Empty;
}
'@

# ===== SMS sender (Twilio) =====
Write-File "$base\Notifications\TwilioSmsSender.cs" @'
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
'@

# ===== Firebase push options =====
Write-File "$base\Notifications\PushOptions.cs" @'
namespace AllInFit.Infrastructure.Notifications;

public sealed class PushOptions
{
    public const string SectionName = "Push";

    public bool Enabled { get; set; }
    public string ServiceAccountPath { get; set; } = string.Empty;
    public string ServiceAccountJson { get; set; } = string.Empty;
    public string AppName { get; set; } = "allinfit";
}
'@

# ===== Firebase push notification =====
Write-File "$base\Notifications\FirebasePushNotificationService.cs" @'
using AllInFit.Shared.Contracts;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Notifications;

/// <summary>
/// Push notification service built on Firebase Cloud Messaging.
/// </summary>
public sealed class FirebasePushNotificationService : IPushNotificationService
{
    private readonly PushOptions _options;
    private readonly ILogger<FirebasePushNotificationService> _logger;
    private readonly FirebaseMessaging _messaging;

    public FirebasePushNotificationService(IOptions<PushOptions> options, ILogger<FirebasePushNotificationService> logger)
    {
        _options = options.Value;
        _logger = logger;

        if (_options.Enabled)
        {
            if (FirebaseApp.DefaultInstance is null)
            {
                var credential = !string.IsNullOrEmpty(_options.ServiceAccountJson)
                    ? GoogleCredential.FromJson(_options.ServiceAccountJson)
                    : GoogleCredential.FromFile(_options.ServiceAccountPath);

                FirebaseApp.Create(new AppOptions { Credential = credential }, _options.AppName);
            }

            _messaging = FirebaseMessaging.GetMessaging(FirebaseApp.DefaultInstance);
        }
        else
        {
            _messaging = null!;
        }
    }

    public async Task SendAsync(PushNotificationMessage message, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(message);

        if (!_options.Enabled || _messaging is null)
        {
            _logger.LogInformation("[PushDisabled] Would push to {UserId}: {Title}", message.UserId, message.Title);
            return;
        }

        var payload = new Dictionary<string, string>
        {
            ["userId"] = message.UserId,
            ["title"] = message.Title,
            ["body"] = message.Body,
        };
        if (!string.IsNullOrEmpty(message.Data)) payload["data"] = message.Data;

        var notification = new Notification { Title = message.Title, Body = message.Body };
        if (!string.IsNullOrEmpty(message.ImageUrl)) notification.ImageUrl = message.ImageUrl;

        var fcmMessage = new Message
        {
            Topic = $"user_{message.UserId}",
            Notification = notification,
            Data = payload
        };

        try
        {
            var response = await _messaging.SendAsync(fcmMessage, cancellationToken);
            _logger.LogInformation("Push sent to {UserId} (response {Response})", message.UserId, response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send push to {UserId}", message.UserId);
            throw;
        }
    }

    public async Task SendToDeviceAsync(string deviceToken, PushNotificationPayload payload, CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled || _messaging is null)
        {
            _logger.LogInformation("[PushDisabled] Would push to device {Token}", deviceToken);
            return;
        }

        var message = new Message
        {
            Token = deviceToken,
            Notification = new Notification { Title = payload.Title, Body = payload.Body, ImageUrl = payload.ImageUrl },
            Data = payload.Data,
            Android = new AndroidConfig { Priority = Priority.High },
            Apns = new ApnsConfig { Aps = new Aps { Sound = "default" } }
        };

        var response = await _messaging.SendAsync(message, cancellationToken);
        _logger.LogInformation("Push sent to device (response {Response})", response);
    }

    public async Task SendToTopicAsync(string topic, PushNotificationPayload payload, CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled || _messaging is null)
        {
            _logger.LogInformation("[PushDisabled] Would push to topic {Topic}", topic);
            return;
        }

        var message = new Message
        {
            Topic = topic,
            Notification = new Notification { Title = payload.Title, Body = payload.Body, ImageUrl = payload.ImageUrl },
            Data = payload.Data
        };

        var response = await _messaging.SendAsync(message, cancellationToken);
        _logger.LogInformation("Push sent to topic {Topic} (response {Response})", topic, response);
    }
}
'@

Write-Host "Infrastructure notifications layer generated successfully!"
