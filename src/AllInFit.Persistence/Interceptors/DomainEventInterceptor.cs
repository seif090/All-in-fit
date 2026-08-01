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
                    await _publisher.Publish(domainEvent, cancellationToken);
                    entity.ClearDomainEvents();
                }
            }
        }

        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }
}