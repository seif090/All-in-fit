namespace AllInFit.Shared.Contracts;

public interface IEmailSender
{
    Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default);
}

public record EmailMessage(
    string To,
    string Subject,
    string Body,
    bool IsHtml = true,
    string? From = null,
    string? ReplyTo = null,
    IReadOnlyList<string>? Cc = null,
    IReadOnlyList<string>? Bcc = null,
    IReadOnlyList<EmailAttachment>? Attachments = null);

public record EmailAttachment(string FileName, byte[] Content, string ContentType);

public interface ISmsSender
{
    Task SendAsync(SmsMessage message, CancellationToken cancellationToken = default);
}

public record SmsMessage(string PhoneNumber, string Text, string? SenderId = null);

public interface IPushNotificationService
{
    Task SendAsync(PushNotificationMessage message, CancellationToken cancellationToken = default);
    Task SendToDeviceAsync(string deviceToken, PushNotificationPayload payload, CancellationToken cancellationToken = default);
    Task SendToTopicAsync(string topic, PushNotificationPayload payload, CancellationToken cancellationToken = default);
}

public record PushNotificationMessage(
    string UserId,
    string Title,
    string Body,
    string? Data = null,
    string? ImageUrl = null);

public record PushNotificationPayload(
    string Title,
    string Body,
    Dictionary<string, string>? Data = null,
    string? ImageUrl = null,
    string? ClickAction = null);