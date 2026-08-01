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