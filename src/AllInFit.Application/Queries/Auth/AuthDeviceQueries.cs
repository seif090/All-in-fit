using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Auth;

public sealed record GetMySessionsQuery(Guid UserId) : IRequest<Result<IReadOnlyList<AuthSessionDto>>>;
public sealed record GetMyDevicesQuery(Guid UserId) : IRequest<Result<IReadOnlyList<AuthDeviceDto>>>;