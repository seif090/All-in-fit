$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== EventBus options =====
Write-File "$base\Messaging\EventBusOptions.cs" @'
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
'@

# ===== RabbitMQ EventBus (singleton) =====
Write-File "$base\Messaging\RabbitMqEventBus.cs" @'
using System.Text;
using System.Text.Json;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace AllInFit.Infrastructure.Messaging;

/// <summary>
/// RabbitMQ-backed event bus. Publishes integration events to a durable topic exchange
/// and dispatches consumed events to registered <see cref="IIntegrationEventHandler{T}"/> handlers
/// resolved through <see cref="IServiceProvider"/>.
/// </summary>
public sealed class RabbitMqEventBus : IEventBus, IDisposable
{
    private readonly IConnection _connection;
    private readonly IChannel _channel;
    private readonly EventBusOptions _options;
    private readonly ILogger<RabbitMqEventBus> _logger;
    private readonly IServiceProvider _services;
    private readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);
    private readonly Dictionary<string, string> _bindings = new(StringComparer.Ordinal);
    private bool _disposed;

    public RabbitMqEventBus(
        IOptions<EventBusOptions> options,
        ILogger<RabbitMqEventBus> logger,
        IServiceProvider services)
    {
        _options = options.Value;
        _logger = logger;
        _services = services;

        var factory = new ConnectionFactory
        {
            HostName = _options.HostName,
            Port = _options.Port,
            UserName = _options.UserName,
            Password = _options.Password,
            VirtualHost = _options.VirtualHost,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
        };

        _connection = factory.CreateConnectionAsync().GetAwaiter().GetResult();
        _channel = _connection.CreateChannelAsync().GetAwaiter().GetResult();

        _channel.ExchangeDeclareAsync(
            exchange: _options.ExchangeName,
            type: ExchangeType.Topic,
            durable: true,
            autoDelete: false,
            arguments: null).GetAwaiter().GetResult();

        _logger.LogInformation("RabbitMQ event bus connected to {Host}:{Port}", _options.HostName, _options.Port);
    }

    public async Task PublishAsync<T>(T integrationEvent, CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
    {
        ArgumentNullException.ThrowIfNull(integrationEvent);

        var payload = JsonSerializer.Serialize(integrationEvent, _jsonOptions);
        var body = Encoding.UTF8.GetBytes(payload);
        var routingKey = typeof(T).Name;

        _logger.LogInformation("Publishing event {EventType} to {Exchange} [{RoutingKey}]",
            typeof(T).Name, _options.ExchangeName, routingKey);

        await _channel.BasicPublishAsync(
            exchange: _options.ExchangeName,
            routingKey: routingKey,
            mandatory: false,
            body: body,
            cancellationToken: cancellationToken);
    }

    public async Task SubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        var eventTypeName = typeof(T).Name;
        var queueName = $"{_options.QueuePrefix}.{eventTypeName}";

        await _channel.QueueDeclareAsync(
            queue: queueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null,
            cancellationToken: cancellationToken);

        await _channel.QueueBindAsync(
            queue: queueName,
            exchange: _options.ExchangeName,
            routingKey: eventTypeName,
            arguments: null,
            cancellationToken: cancellationToken);

        if (_bindings.ContainsKey(eventTypeName))
        {
            _logger.LogInformation("Subscription already exists for {EventType}; skipping consumer setup.", eventTypeName);
            return;
        }

        _bindings[eventTypeName] = queueName;

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                var @event = JsonSerializer.Deserialize(json, typeof(T), _jsonOptions);
                if (@event is T typedEvent)
                {
                    using var scope = _services.CreateScope();
                    var handler = scope.ServiceProvider.GetService<THandler>();
                    if (handler is not null)
                    {
                        await handler.HandleAsync(typedEvent, CancellationToken.None);
                    }
                    else
                    {
                        _logger.LogWarning("No handler registered for {EventType} of type {HandlerType}", eventTypeName, typeof(THandler).Name);
                    }
                }

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing event {EventType} from queue {Queue}", eventTypeName, queueName);
                await _channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: true, cancellationToken: CancellationToken.None);
            }
        };

        await _channel.BasicConsumeAsync(queue: queueName, autoAck: false, consumer: consumer, cancellationToken: cancellationToken);

        _logger.LogInformation("Subscribed {HandlerType} for event {EventType} on queue {Queue}",
            typeof(THandler).Name, eventTypeName, queueName);
    }

    public async Task UnsubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        var eventTypeName = typeof(T).Name;
        if (_bindings.Remove(eventTypeName, out var queueName))
        {
            await _channel.QueueUnbindAsync(queueName, _options.ExchangeName, eventTypeName, null, cancellationToken);
        }

        _logger.LogInformation("Unsubscribed {HandlerType} for event {EventType}", typeof(THandler).Name, eventTypeName);
    }

    public void Dispose()
    {
        if (_disposed) return;
        _channel?.Dispose();
        _connection?.Dispose();
        _disposed = true;
    }
}
'@

Write-Host "Infrastructure messaging layer generated successfully!"
