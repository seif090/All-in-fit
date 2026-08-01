using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Files;

public sealed class StoredFile : SoftDeleteEntity
{
    public string FileName { get; set; } = string.Empty;
    public string? OriginalName { get; set; }
    public string ContentType { get; set; } = string.Empty;
    public long SizeInBytes { get; set; }
    public string? StorageProvider { get; set; }
    public string? FileKey { get; set; }
    public string? PublicUrl { get; set; }
    public string? Folder { get; set; }
    public string? Metadata { get; set; }
    public Guid? UploadedByUserId { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}