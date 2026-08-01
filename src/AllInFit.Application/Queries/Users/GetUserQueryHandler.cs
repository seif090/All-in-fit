using AllInFit.Application.Ports;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed class GetUserQueryHandler : IRequestHandler<GetUserQuery, Result<UserDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetUserQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<UserDto>> Handle(GetUserQuery request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<UserDto>(new Error("User.NotFound", "User not found"));
    }
}

public sealed class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, Result<UserDto>>
{
    public async Task<Result<UserDto>> Handle(GetCurrentUserQuery request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<UserDto>(new Error("User.NotAuthenticated", "User not authenticated"));
    }
}