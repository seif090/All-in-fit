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

        return new FileUploadResult(true, result.PublicId, result.SecureUrl?.ToString(), result.PublicId, result.Bytes, null);
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