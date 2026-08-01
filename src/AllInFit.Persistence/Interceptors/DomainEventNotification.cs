using AllInFit.Domain.Common;
using MediatR;

namespace AllInFit.Persistence.Interceptors;

public sealed class DomainEventNotification<TDomainEvent> : INotification
    where TDomainEvent : DomainEvent
{
    public TDomainEvent DomainEvent { get; }
    public DomainEventNotification(TDomainEvent domainEvent) => DomainEvent = domainEvent;
}