$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"
$domain = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed: $path"
}

# ===== Fix Review.cs - remove hidden CreatedAt =====
Write-File "$domain\Entities\Reviews\Review.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Reviews;

public sealed class Review : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public int Rating { get; set; }
    public string? Title { get; set; }
    public string? Comment { get; set; }
    public Guid? GymId { get; set; }
    public Guid? GymBranchId { get; set; }
    public Guid? TrainerId { get; set; }
    public Guid? DoctorId { get; set; }
    public Guid? NutritionistId { get; set; }
    public Guid? ProductId { get; set; }
    public Guid? WorkoutProgramId { get; set; }
    public Guid? MealPlanId { get; set; }
    public bool IsApproved { get; set; }
    public bool IsVerifiedPurchase { get; set; }
}
'@

# ===== Fix ProductSpecifications.cs - null-safe Description =====
Write-File "$domain\Specifications\ProductSpecifications.cs" @'
using AllInFit.Domain.Entities.Marketplace;

namespace AllInFit.Domain.Specifications;

public sealed class AvailableProductsSpecification : BaseSpecification<Product>
{
    public AvailableProductsSpecification(string? searchTerm = null, Guid? categoryId = null, decimal? minPrice = null, decimal? maxPrice = null)
        : base(p =>
            p.IsAvailable &&
            !p.IsDeleted &&
            (string.IsNullOrWhiteSpace(searchTerm) ||
             p.Name.Contains(searchTerm!) ||
             (!string.IsNullOrEmpty(p.Description) && p.Description.Contains(searchTerm!) && searchTerm != null)) &&
            (categoryId == null || p.CategoryId == categoryId) &&
            (minPrice == null || p.Price >= minPrice) &&
            (maxPrice == null || p.Price <= maxPrice))
    {
        ApplyOrderByDescending(p => p.CreatedAt);
    }
}

public sealed class ProductByIdSpecification : BaseSpecification<Product>
{
    public ProductByIdSpecification(Guid productId) : base(p => p.Id == productId && !p.IsDeleted)
    {
        AddInclude(p => p.Brand);
    }
}
'@

# ===== Fix User.cs HasPermission null-safe =====
Write-File "$domain\Entities\Identity\User.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Events;

namespace AllInFit.Domain.Entities.Identity;

public sealed class User : SoftDeleteEntity
{
    private readonly List<RefreshToken> _refreshTokens = new();
    private readonly List<UserDevice> _devices = new();
    private readonly List<UserRole> _userRoles = new();
    private readonly List<UserSession> _sessions = new();

    private User() { }

    public User(string email, string firstName, string lastName, string passwordHash)
    {
        Email = email; FirstName = firstName; LastName = lastName; PasswordHash = passwordHash;
        IsEmailVerified = false; IsActive = true; AccountType = AccountType.User;
    }

    public string Email { get; private set; } = string.Empty;
    public string FirstName { get; private set; } = string.Empty;
    public string LastName { get; private set; } = string.Empty;
    public string? PhoneNumber { get; private set; }
    public string? PhoneCountryCode { get; private set; }
    public bool IsPhoneVerified { get; private set; }
    public string PasswordHash { get; private set; } = string.Empty;
    public bool IsEmailVerified { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsLockedOut { get; private set; }
    public DateTime? LockoutEnd { get; private set; }
    public int AccessFailedCount { get; private set; }
    public DateTime? LastLoginAt { get; private set; }
    public string? ProfilePictureUrl { get; private set; }
    public string? Bio { get; private set; }
    public DateTime? DateOfBirth { get; private set; }
    public Gender Gender { get; private set; }
    public string? GoogleId { get; private set; }
    public bool IsGoogleAccount { get; private set; }
    public string? OtpCode { get; private set; }
    public DateTime? OtpExpiresAt { get; private set; }
    public AccountType AccountType { get; private set; }
    public string? RefreshToken { get; private set; }
    public DateTime? RefreshTokenExpiresAt { get; private set; }

    public IReadOnlyCollection<RefreshToken> RefreshTokens => _refreshTokens.AsReadOnly();
    public IReadOnlyCollection<UserDevice> Devices => _devices.AsReadOnly();
    public IReadOnlyCollection<UserRole> UserRoles => _userRoles.AsReadOnly();
    public IReadOnlyCollection<UserSession> Sessions => _sessions.AsReadOnly();
    public string FullName => $"{FirstName} {LastName}";

    public void VerifyEmail() { IsEmailVerified = true; AddDomainEvent(new UserEmailVerifiedDomainEvent(Id, Email)); }
    public void UpdateProfile(string fn, string ln, string? ph, string? bio, DateTime? dob, Gender g) { FirstName = fn; LastName = ln; PhoneNumber = ph; Bio = bio; DateOfBirth = dob; Gender = g; UpdatedAt = DateTime.UtcNow; }
    public void UpdatePassword(string hash) { PasswordHash = hash; UpdatedAt = DateTime.UtcNow; }
    public void RecordLogin() { LastLoginAt = DateTime.UtcNow; AccessFailedCount = 0; }
    public void RecordFailedLogin() { AccessFailedCount++; if (AccessFailedCount >= 5) { IsLockedOut = true; LockoutEnd = DateTime.UtcNow.AddMinutes(15); } }
    public void SetGoogleAccount(string googleId) { GoogleId = googleId; IsGoogleAccount = true; IsEmailVerified = true; }
    public void SetOtp(string code, DateTime expires) { OtpCode = code; OtpExpiresAt = expires; }
    public bool VerifyOtp(string code) { if (OtpCode != code || OtpExpiresAt < DateTime.UtcNow) return false; OtpCode = null; OtpExpiresAt = null; IsPhoneVerified = true; return true; }
    public void AddRole(Role role) { if (!_userRoles.Any(ur => ur.RoleId == role.Id)) _userRoles.Add(new UserRole { UserId = Id, RoleId = role.Id }); }
    public void RemoveRole(Role role) { var ur = _userRoles.FirstOrDefault(x => x.RoleId == role.Id); if (ur != null) _userRoles.Remove(ur); }
    public bool HasRole(string name) => _userRoles.Any(ur => ur.Role?.Name == name);
    public bool HasPermission(string perm) => _userRoles.Any(ur => ur.Role != null && ur.Role.RolePermissions.Any(rp => rp.Permission != null && rp.Permission.Name == perm));
    public void AddDevice(UserDevice device) { var existing = _devices.FirstOrDefault(d => d.DeviceId == device.DeviceId); if (existing != null) _devices.Remove(existing); _devices.Add(device); }
    public void RemoveDevice(string deviceId) { var d = _devices.FirstOrDefault(x => x.DeviceId == deviceId); if (d != null) _devices.Remove(d); }
    public void Deactivate() { IsActive = false; DeletedAt = DateTime.UtcNow; }
    public void Reactivate() { IsActive = true; DeletedAt = null; }
}
'@

# ===== Fix SmtpEmailSender.cs - retain BodyBuilder reference =====
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

        var builder = new BodyBuilder
        {
            HtmlBody = message.IsHtml ? message.Body : null,
            TextBody = message.IsHtml ? null : message.Body
        };

        if (message.Attachments is not null)
        {
            foreach (var attachment in message.Attachments)
            {
                builder.Attachments.Add(attachment.FileName, attachment.Content, ContentType.Parse(attachment.ContentType));
            }
        }

        var mime = new MimeMessage
        {
            Subject = message.Subject,
            Body = builder.ToMessageBody()
        };

        mime.From.Add(new MailboxAddress(_options.FromName, message.From ?? _options.From));
        mime.To.Add(MailboxAddress.Parse(message.To));

        if (!string.IsNullOrWhiteSpace(message.ReplyTo))
            mime.ReplyTo.Add(MailboxAddress.Parse(message.ReplyTo));

        foreach (var cc in message.Cc ?? [])
            mime.Cc.Add(MailboxAddress.Parse(cc));
        foreach (var bcc in message.Bcc ?? [])
            mime.Bcc.Add(MailboxAddress.Parse(bcc));

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

# ===== Fix AzureBlobFileStorage.cs =====
Write-File "$base\Storage\AzureBlobFileStorage.cs" @'
using AllInFit.Shared.Contracts;
using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace AllInFit.Infrastructure.Storage;

/// <summary>
/// Stores files on Azure Blob Storage.
/// </summary>
public sealed class AzureBlobFileStorage : IFileStorage
{
    private readonly BlobContainerClient _container;
    private readonly StorageOptions _options;

    public AzureBlobFileStorage(StorageOptions options)
    {
        _options = options;
        var service = new BlobServiceClient(options.AzureBlob.ConnectionString);
        _container = service.GetBlobContainerClient(options.AzureBlob.ContainerName);
        _container.CreateIfNotExists();
    }

    public async Task<FileUploadResult> UploadAsync(FileUploadRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var folder = string.IsNullOrWhiteSpace(request.Folder) ? "" : request.Folder.Trim('/');
        var dateFolder = DateTime.UtcNow.ToString("yyyy/MM");
        var blobName = string.IsNullOrEmpty(folder)
            ? $"{dateFolder}/{Guid.NewGuid():N}_{Path.GetFileName(request.FileName)}"
            : $"{folder}/{dateFolder}/{Guid.NewGuid():N}_{Path.GetFileName(request.FileName)}";

        // Buffer into memory to determine size and allow reset
        var buffer = new MemoryStream();
        await request.Content.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;
        var size = buffer.Length;

        var blob = _container.GetBlobClient(blobName);

        var options = new BlobUploadOptions
        {
            HttpHeaders = new BlobHttpHeaders
            {
                ContentType = request.ContentType,
                ContentDisposition = $"inline; filename={Path.GetFileName(request.FileName)}"
            },
            Conditions = new BlobRequestConditions { IfNoneMatch = ETag.All },
            AccessTier = AccessTier.Hot,
            Metadata = request.Metadata
        };

        await blob.UploadAsync(buffer, options, cancellationToken);

        return new FileUploadResult(true, blobName, blob.Uri.ToString(), blobName, size, null);
    }

    public async Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        try
        {
            var blob = _container.GetBlobClient(fileKey);
            if (!await blob.ExistsAsync(cancellationToken))
                return new FileDownloadResult(false, null, null, null, "Blob not found");

            var stream = new MemoryStream();
            await blob.DownloadToAsync(stream, cancellationToken);
            stream.Position = 0;

            return new FileDownloadResult(true, stream, "application/octet-stream", Path.GetFileName(fileKey), null);
        }
        catch (Exception ex)
        {
            return new FileDownloadResult(false, null, null, null, ex.Message);
        }
    }

    public async Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var result = await _container.GetBlobClient(fileKey).DeleteIfExistsAsync(cancellationToken: cancellationToken);
        return result.Value;
    }

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
        => Task.FromResult(_container.GetBlobClient(fileKey).Uri.ToString());

    public async Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var result = await _container.GetBlobClient(fileKey).ExistsAsync(cancellationToken);
        return result.Value;
    }
}
'@

# ===== Fix CloudinaryFileStorage.cs =====
Write-File "$base\Storage\CloudinaryFileStorage.cs" @'
using AllInFit.Shared.Contracts;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace AllInFit.Infrastructure.Storage;

/// <summary>
/// Stores files on Cloudinary.
/// </summary>
public sealed class CloudinaryFileStorage : IFileStorage
{
    private readonly Cloudinary _cloudinary;
    private readonly StorageOptions _options;

    public CloudinaryFileStorage(StorageOptions options)
    {
        _options = options;
        var account = new Account(
            options.Cloudinary.CloudName,
            options.Cloudinary.ApiKey,
            options.Cloudinary.ApiSecret);
        _cloudinary = new Cloudinary(account);
    }

    public async Task<FileUploadResult> UploadAsync(FileUploadRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        // Buffer into memory to reset position after upload
        var buffer = new MemoryStream();
        await request.Content.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;

        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(Path.GetFileName(request.FileName), buffer),
            PublicId = string.IsNullOrWhiteSpace(request.Folder)
                ? null
                : $"{request.Folder.Trim('/')}/{Guid.NewGuid():N}_{Path.GetFileNameWithoutExtension(request.FileName)}",
            UseFilename = true,
            UniqueFilename = true,
            Overwrite = false,
            Folder = string.IsNullOrWhiteSpace(request.Folder) ? null : request.Folder.Trim('/')
        };

        var result = await _cloudinary.UploadAsync(uploadParams, cancellationToken);
        if (result.Error is not null)
        {
            return new FileUploadResult(false, null, null, null, null, result.Error.Message);
        }

        return new FileUploadResult(true, result.PublicId, result.SecureUrl?.ToString(), result.PublicId, result.Bytes?.Length, null);
    }

    public Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default)
        => throw new NotSupportedException("Cloudinary serves files via CDN URLs; use GetUrlAsync.");

    public Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var deletionParams = new DeletionParams(fileKey);
        try
        {
            var result = _cloudinary.DestroyAsync(deletionParams).GetAwaiter().GetResult();
            return Task.FromResult(result.Result == "ok");
        }
        catch
        {
            return Task.FromResult(false);
        }
    }

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var url = _cloudinary.Api.UrlImgUp.BuildUrl(fileKey);
        return Task.FromResult(url);
    }

    public async Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        try
        {
            var getResource = new GetResourceParams(fileKey);
            var resource = await _cloudinary.GetResourceAsync(getResource);
            return resource is not null && resource.JsonObj is not null;
        }
        catch
        {
            return false;
        }
    }
}
'@

Write-Host "Infrastructure fixes applied successfully!"
