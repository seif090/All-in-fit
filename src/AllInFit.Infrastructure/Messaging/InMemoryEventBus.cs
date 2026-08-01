using AllInFit.Shared.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Messaging;

/// <summary>
/// In-process event bus used when RabbitMQ is disabled.
/// Handlers are dispatched synchronously via the service provider.
/// </summary>
public sealed class InMemoryEventBus : IEventBus
{
    private readonly IServiceProvider _services;
    private readonly ILogger<InMemoryEventBus> _logger;

    public InMemoryEventBus(IServiceProvider services, ILogger<InMemoryEventBus> logger)
    {
        _services = services;
        _logger = logger;
    }

    public async Task PublishAsync<T>(T integrationEvent, CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
    {
        ArgumentNullException.ThrowIfNull(integrationEvent);

        using var scope = _services.CreateScope();
        var handlers = scope.ServiceProvider.GetServices<IIntegrationEventHandler<T>>().ToArray();

        if (handlers.Length == 0)
        {
            _logger.LogDebug("No handlers registered for {EventType}", typeof(T).Name);
            return;
        }

        _logger.LogInformation("Dispatching {EventType} to {HandlerCount} handler(s)", typeof(T).Name, handlers.Length);
        foreach (var handler in handlers)
        {
            await handler.HandleAsync(integrationEvent, cancellationToken);
        }
    }

    public Task SubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        _logger.LogDebug("In-memory bus: subscription for {EventType} is implicit", typeof(T).Name);
        return Task.CompletedTask;
    }

    public Task UnsubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>
    {
        _logger.LogDebug("In-memory bus: unsubscription for {EventType} is implicit", typeof(T).Name);
        return Task.CompletedTask;
    }
}