namespace AllInFit.Infrastructure.Caching;

public sealed class CacheOptions
{
    public const string SectionName = "Cache";

    public bool Enabled { get; set; }
    public string? RedisConnectionString { get; set; }
    public int DefaultExpirationMinutes { get; set; } = 30;
}