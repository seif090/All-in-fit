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