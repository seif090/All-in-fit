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