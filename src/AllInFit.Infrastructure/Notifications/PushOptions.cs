namespace AllInFit.Infrastructure.Notifications;

public sealed class PushOptions
{
    public const string SectionName = "Push";

    public bool Enabled { get; set; }
    public string ServiceAccountPath { get; set; } = string.Empty;
    public string ServiceAccountJson { get; set; } = string.Empty;
    public string AppName { get; set; } = "allinfit";
}