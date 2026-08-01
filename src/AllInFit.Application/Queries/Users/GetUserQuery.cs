using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed record GetUserQuery(Guid UserId) : IRequest<Result<UserDto>>;
public sealed record GetCurrentUserQuery(Guid UserId) : IRequest<Result<UserDto>>;

public sealed record UserDto(
    Guid Id,
    string Email,
    string? FirstName,
    string? LastName,
    string? PhoneNumber,
    bool IsActive,
    DateTime CreatedAt);