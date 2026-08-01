namespace AllInFit.Shared.Contracts;

/// <summary>
/// Represents an integration event for the event bus.
/// </summary>
public interface IIntegrationEvent
{
    Guid Id { get; }
    DateTime OccurredOn { get; }
}

/// <summary>
/// Abstraction for the message broker (RabbitMQ).
/// Supports publish/subscribe for integration events.
/// </summary>
public interface IEventBus
{
    Task PublishAsync<T>(T integrationEvent, CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent;

Task SubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>;

    Task UnsubscribeAsync<T, THandler>(CancellationToken cancellationToken = default)
        where T : class, IIntegrationEvent
        where THandler : IIntegrationEventHandler<T>;
}

public interface IIntegrationEventHandler<in T>
    where T : IIntegrationEvent
{
    Task HandleAsync(T integrationEvent, CancellationToken cancellationToken = default);
}
