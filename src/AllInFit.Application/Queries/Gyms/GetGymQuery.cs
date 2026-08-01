using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Gyms;

public sealed record GetGymQuery(Guid GymId) : IRequest<Result<GymDto>>;

public sealed record GymDto(
    Guid Id,
    string Name,
    string LegalName,
    string? LogoUrl,
    string? Description,
    bool IsVerified,
    bool IsActive,
    double? Rating,
    int ReviewCount);