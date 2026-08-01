$base = "c:\Users\seaif\Desktop\All in fit"

# 1. Create DomainEventNotification wrapper (implements MediatR INotification)
$wrapperPath = "$base\src\AllInFit.Persistence\Interceptors\DomainEventNotification.cs"
$wrapperContent = @'
using AllInFit.Domain.Common;
using MediatR;

namespace AllInFit.Persistence.Interceptors;

public sealed class DomainEventNotification<TDomainEvent> : INotification
    where TDomainEvent : DomainEvent
{
    public TDomainEvent DomainEvent { get; }
    public DomainEventNotification(TDomainEvent domainEvent) => DomainEvent = domainEvent;
}
'@
[System.IO.File]::WriteAllText($wrapperPath, $wrapperContent, [System.Text.Encoding]::UTF8)
Write-Host "Created: $wrapperPath"

# 2. Update DomainEventInterceptor to wrap domain events before publishing
$interceptorPath = "$base\src\AllInFit.Persistence\Interceptors\DomainEventInterceptor.cs"
$interceptorContent = @'
using AllInFit.Domain.Common;
using MediatR;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace AllInFit.Persistence.Interceptors;

public sealed class DomainEventInterceptor : SaveChangesInterceptor
{
    private readonly IPublisher _publisher;

    public DomainEventInterceptor(IPublisher publisher)
    {
        _publisher = publisher;
    }

    public override async ValueTask<int> SavedChangesAsync(SaveChangesCompletedEventData eventData, int result, CancellationToken cancellationToken = default)
    {
        if (eventData.Context is not null)
        {
            var entities = eventData.Context.ChangeTracker
                .Entries<BaseEntity>()
                .Where(e => e.Entity.DomainEvents.Count > 0)
                .Select(e => e.Entity)
                .ToList();

            foreach (var entity in entities)
            {
                foreach (var domainEvent in entity.DomainEvents.ToList())
                {
                    var notificationType = typeof(DomainEventNotification<>).MakeGenericType(domainEvent.GetType());
                    var notification = Activator.CreateInstance(notificationType, domainEvent);

                    if (notification is INotification source)
                    {
                        await _publisher.Publish(source, cancellationToken);
                    }

                    entity.ClearDomainEvents();
                }
            }
        }

        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }
}
'@
[System.IO.File]::WriteAllText($interceptorPath, $interceptorContent, [System.Text.Encoding]::UTF8)
Write-Host "Updated: $interceptorPath"

Write-Host "Domain event fix complete."
