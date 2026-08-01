$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== File storage options =====
Write-File "$base\Storage\StorageOptions.cs" @'
using AllInFit.Shared.Contracts;

namespace AllInFit.Infrastructure.Storage;

public sealed class StorageOptions
{
    public const string SectionName = "Storage";

    public FileStorageProvider Provider { get; set; } = FileStorageProvider.Local;
    public LocalStorageOptions Local { get; set; } = new();
    public CloudinaryOptions Cloudinary { get; set; } = new();
    public AwsS3Options AwsS3 { get; set; } = new();
    public AzureBlobOptions AzureBlob { get; set; } = new();
}

public sealed class LocalStorageOptions
{
    public string RootPath { get; set; } = "wwwroot/uploads";
    public string BaseUrl { get; set; } = "/uploads";
}

public sealed class CloudinaryOptions
{
    public string CloudName { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string ApiSecret { get; set; } = string.Empty;
}

public sealed class AwsS3Options
{
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string Bucket { get; set; } = string.Empty;
    public string Region { get; set; } = "eu-west-1";
}

public sealed class AzureBlobOptions
{
    public string ConnectionString { get; set; } = string.Empty;
    public string ContainerName { get; set; } = "allinfit";
}
'@

# ===== Local file storage =====
Write-File "$base\Storage\LocalFileStorage.cs" @'
using AllInFit.Shared.Contracts;

namespace AllInFit.Infrastructure.Storage;

/// <summary>
/// Stores files on the local filesystem. Suitable for development and single-node hosting.
/// </summary>
public sealed class LocalFileStorage : IFileStorage
{
    private readonly StorageOptions _options;

    public LocalFileStorage(StorageOptions options)
    {
        _options = options;
    }

    public async Task<FileUploadResult> UploadAsync(FileUploadRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        try
        {
            var safeFileName = Path.GetFileName(request.FileName);
            var folder = string.IsNullOrWhiteSpace(request.Folder) ? "" : request.Folder.Trim('/');
            var dateFolder = DateTime.UtcNow.ToString("yyyy/MM");
            var relativeDir = Path.Combine(folder, dateFolder);
            var fullDir = Path.Combine(_options.Local.RootPath, relativeDir);
            Directory.CreateDirectory(fullDir);

            var key = Path.Combine(relativeDir, $"{Guid.NewGuid():N}_{safeFileName}").Replace('\\', '/');
            var fullPath = Path.Combine(_options.Local.RootPath, key);

            await using var fs = File.Create(fullPath);
            await request.Content.CopyToAsync(fs, cancellationToken);
            var size = fs.Length;

            var url = $"{_options.Local.BaseUrl}/{key}";

            return new FileUploadResult(true, key, url, key, size, null);
        }
        catch (Exception ex)
        {
            return new FileUploadResult(false, null, null, null, null, ex.Message);
        }
    }

    public async Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var safeKey = fileKey.Replace('/', Path.DirectorySeparatorChar).TrimStart(Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(_options.Local.RootPath, safeKey);

        if (!File.Exists(fullPath))
            return new FileDownloadResult(false, null, null, null, "File not found");

        var stream = await Task.FromResult(File.OpenRead(fullPath));
        return new FileDownloadResult(true, stream, "application/octet-stream", Path.GetFileName(fileKey), null);
    }

    public Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var safeKey = fileKey.Replace('/', Path.DirectorySeparatorChar).TrimStart(Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(_options.Local.RootPath, safeKey);
        if (!File.Exists(fullPath)) return Task.FromResult(false);
        File.Delete(fullPath);
        return Task.FromResult(true);
    }

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
        => Task.FromResult($"{_options.Local.BaseUrl}/{fileKey.TrimStart('/')}");

    public Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var safeKey = fileKey.Replace('/', Path.DirectorySeparatorChar).TrimStart(Path.DirectorySeparatorChar);
        return Task.FromResult(File.Exists(Path.Combine(_options.Local.RootPath, safeKey)));
    }
}
'@

# ===== Cloudinary file storage =====
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

        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(Path.GetFileName(request.FileName), request.Content),
            PublicId = string.IsNullOrWhiteSpace(request.Folder)
                ? null
                : $"{request.Folder.Trim('/')}/{Guid.NewGuid():N}_{Path.GetFileNameWithoutExtension(request.FileName)}",
            Folder = string.IsNullOrWhiteSpace(request.Folder) ? null : null,
            UseFilename = true,
            UniqueFilename = true,
            Overwrite = false
        };

        var result = await _cloudinary.UploadAsync(uploadParams, cancellationToken);
        if (result.Error is not null)
        {
            return new FileUploadResult(false, null, null, null, null, result.Error.Message);
        }

        return new FileUploadResult(true, result.PublicId, result.SecureUrl?.ToString(), result.PublicId, result.Length, null);
    }

    public Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default)
        => throw new NotSupportedException("Cloudinary serves files via CDN URLs; use GetUrlAsync.");

    public Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var deletionParams = new DeletionParams(fileKey);
        return _cloudinary.DestroyAsync(deletionParams, cancellationToken)
            .ContinueWith(t => t.Result.Result == "ok", CancellationToken.None);
    }

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var url = _cloudinary.Api.UrlImgUp.BuildUrl(fileKey);
        return Task.FromResult(url);
    }

    public Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        var getResource = new GetResourceParams(fileKey);
        return _cloudinary.GetResourceAsync(getResource, cancellationToken)
            .ContinueWith(t => t.Result is { StatusCode: 200 } or { StatusCode: 2000 }, CancellationToken.None);
    }
}
'@

# ===== AWS S3 file storage =====
Write-File "$base\Storage\AwsS3FileStorage.cs" @'
using AllInFit.Shared.Contracts;
using Amazon;
using Amazon.S3;
using Amazon.S3.Model;

namespace AllInFit.Infrastructure.Storage;

/// <summary>
/// Stores files on AWS S3.
/// </summary>
public sealed class AwsS3FileStorage : IFileStorage
{
    private readonly IAmazonS3 _s3;
    private readonly StorageOptions _options;

    public AwsS3FileStorage(StorageOptions options)
    {
        _options = options;
        var region = RegionEndpoint.GetBySystemName(options.AwsS3.Region);
        var creds = new Amazon.Runtime.BasicAWSCredentials(options.AwsS3.AccessKey, options.AwsS3.SecretKey);
        _s3 = new AmazonS3Client(creds, region);
    }

    public async Task<FileUploadResult> UploadAsync(FileUploadRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var folder = string.IsNullOrWhiteSpace(request.Folder) ? "" : request.Folder.Trim('/');
        var dateFolder = DateTime.UtcNow.ToString("yyyy/MM");
        var key = string.IsNullOrEmpty(folder)
            ? $"{dateFolder}/{Guid.NewGuid():N}_{Path.GetFileName(request.FileName)}"
            : $"{folder}/{dateFolder}/{Guid.NewGuid():N}_{Path.GetFileName(request.FileName)}";

        var putRequest = new PutObjectRequest
        {
            BucketName = _options.AwsS3.Bucket,
            Key = key,
            InputStream = request.Content,
            ContentType = request.ContentType,
            AutoCloseStream = true
        };

        if (!request.IsPublic)
        {
            putRequest.ServerSideEncryptionMethod = ServerSideEncryptionMethod.AES256;
        }

        var response = await _s3.PutObjectAsync(putRequest, cancellationToken);
        if (response.HttpStatusCode != System.Net.HttpStatusCode.OK && response.HttpStatusCode != System.Net.HttpStatusCode.NoContent)
        {
            return new FileUploadResult(false, null, null, null, null, $"S3 upload failed: {response.HttpStatusCode}");
        }

        return new FileUploadResult(true, key, _s3.GetPreSignedURL(new GetPreSignedUrlRequest
        {
            BucketName = _options.AwsS3.Bucket,
            Key = key,
            Expires = DateTime.UtcNow.AddDays(7)
        }), null, null, null);
    }

    public async Task<FileDownloadResult> DownloadAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _s3.GetObjectAsync(_options.AwsS3.Bucket, fileKey, cancellationToken);
            return new FileDownloadResult(true, response.ResponseStream, response.Headers.ContentType, Path.GetFileName(fileKey), null);
        }
        catch (AmazonS3Exception ex)
        {
            return new FileDownloadResult(false, null, null, null, ex.Message);
        }
    }

    public Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
        => _s3.DeleteObjectAsync(_options.AwsS3.Bucket, fileKey, cancellationToken)
            .ContinueWith(t => t.IsCompletedSuccessfully, CancellationToken.None);

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
        => Task.FromResult($"https://{_options.AwsS3.Bucket}.s3.{_options.AwsS3.Region}.amazonaws.com/{fileKey}");

    public async Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
    {
        try
        {
            await _s3.GetObjectMetadataAsync(_options.AwsS3.Bucket, fileKey, cancellationToken);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
    }
}
'@

# ===== Azure Blob file storage =====
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
            Metadata = request.Metadata,
            TransferOptions = new Azure.Storage.TransferOptions { InitialTransferSize = 4 * 1024 * 1024 }
        };

        var response = await blob.UploadAsync(request.Content, options, cancellationToken);

        return new FileUploadResult(true, blobName, blob.Uri.ToString(), blobName, response.Value.ContentLength, null);
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

    public Task<bool> DeleteAsync(string fileKey, CancellationToken cancellationToken = default)
        => _container.GetBlobClient(fileKey).DeleteIfExistsAsync(cancellationToken: cancellationToken);

    public Task<string> GetUrlAsync(string fileKey, CancellationToken cancellationToken = default)
        => Task.FromResult(_container.GetBlobClient(fileKey).Uri.ToString());

    public Task<bool> ExistsAsync(string fileKey, CancellationToken cancellationToken = default)
        => _container.GetBlobClient(fileKey).ExistsAsync(cancellationToken);
}
'@

Write-Host "Infrastructure file storage layer generated successfully!"
