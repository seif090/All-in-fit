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