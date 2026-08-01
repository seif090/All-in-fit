namespace AllInFit.Infrastructure.Messaging;

public sealed class EventBusOptions
{
    public const string SectionName = "EventBus";

    public bool Enabled { get; set; }
    public string HostName { get; set; } = "localhost";
    public int Port { get; set; } = 5672;
    public string UserName { get; set; } = "guest";
    public string Password { get; set; } = "guest";
    public string ExchangeName { get; set; } = "allinfit.events";
    public string QueuePrefix { get; set; } = "allinfit";
    public string VirtualHost { get; set; } = "/";
}