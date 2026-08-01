using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Gyms;

public sealed record CreateGymCommand(
    string Name,
    string LegalName,
    string? LogoUrl,
    string? Description,
    string? Website,
    Guid OwnerUserId) : IRequest<Result<Guid>>;

public sealed record UpdateGymCommand(Guid GymId, string Name, string? Description) : IRequest<Result>;

public sealed record DeleteGymCommand(Guid GymId) : IRequest<Result>;