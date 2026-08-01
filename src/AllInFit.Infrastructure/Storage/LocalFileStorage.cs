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