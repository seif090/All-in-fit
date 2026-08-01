namespace AllInFit.Infrastructure.Jobs;

public sealed class HangfireOptions
{
    public const string SectionName = "Hangfire";

    public bool Enabled { get; set; } = false;
    public string? DashboardPath { get; set; } = "/hangfire";
    public int WorkerCount { get; set; } = 4;
    public string[] Queues { get; set; } = ["default", "notifications", "payments", "reports"];
}