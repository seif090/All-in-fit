using AllInFit.Domain.Common;

namespace AllInFit.Domain.Events;

public sealed record UserRegisteredDomainEvent(Guid UserId, string Email, string FullName) : DomainEvent;