namespace AllInFit.Shared.Contracts;

/// <summary>
/// Abstraction for file storage providers (Local, Cloudinary, AWS S3, Azure Blob).
/// </summary>
public interface IFileStorage
{
    Task<FileUploadResult> UploadAsync(FileUploadRequest request, CancellationToken cancellationToken = default);
    Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default);
    Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default);
}

public record FileUploadRequest(
    Stream Content,
    string FileName,
    string ContentType,
    string? Folder = null,
    bool IsPublic = true,
    Dictionary<string, string>? Metadata = null);

public record FileUploadResult(
    bool Success,
    string? FileKey,
    string? Url,
    string? PublicId,
    long? Size,
    string? Error);

public record FileDownloadResult(
    bool Success,
    Stream? Content,
    string? ContentType,
    string? FileName,
    string? Error);

/// <summary>
/// Supported file storage providers.
/// </summary>
public enum FileStorageProvider
{
    Local,
    Cloudinary,
    AwsS3,
    AzureBlob
}
