$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"
$persistence = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Persistence"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# Remove EF Core dependency from Domain — rewrite SpecificationEvaluator to be EF-agnostic
Write-File "$base\Specifications\SpecificationEvaluator.cs" @'
namespace AllInFit.Domain.Specifications;

/// <summary>
/// Evaluates specifications against IQueryable to produce the final query.
/// Domain-agnostic — does not depend on EF Core.
/// </summary>
public static class SpecificationEvaluator<T>
{
    public static IQueryable<T> GetQuery(IQueryable<T> inputQuery, ISpecification<T> specification)
    {
        var query = inputQuery;

        if (specification.Criteria is not null)
            query = query.Where(specification.Criteria);

        if (specification.IsDistinct)
            query = query.Distinct();

        if (specification.OrderBy is not null)
            query = query.OrderBy(specification.OrderBy);
        else if (specification.OrderByDescending is not null)
            query = query.OrderByDescending(specification.OrderByDescending);

        if (specification.IsPagingEnabled)
            query = query.Skip(specification.Skip).Take(specification.Take);

        return query;
    }
}
'@

# Verify no corruption remains in INotificationService — rewrite clean
Write-File "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Shared\Contracts\INotificationService.cs" @'
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
'@

Write-Host "Fixes applied successfully!"
