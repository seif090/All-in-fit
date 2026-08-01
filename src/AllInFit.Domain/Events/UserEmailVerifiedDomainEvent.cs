using AllInFit.Domain.Common;

namespace AllInFit.Domain.Events;

public sealed record UserEmailVerifiedDomainEvent(Guid UserId, string Email) : DomainEvent;