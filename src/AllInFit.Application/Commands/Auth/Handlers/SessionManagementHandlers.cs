using AllInFit.Application.Ports;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class LogoutAllDevicesCommandHandler : IRequestHandler<LogoutAllDevicesCommand, Result>
{
    private readonly IAuthSessionService _authSessionService;

    public LogoutAllDevicesCommandHandler(IAuthSessionService authSessionService) => _authSessionService = authSessionService;

    public async Task<Result> Handle(LogoutAllDevicesCommand request, CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            return Result.Failure(new Error("User.NotAuthenticated", "User not authenticated", ErrorType.Unauthorized));

        await _authSessionService.LogoutAllDevicesAsync(request.UserId, cancellationToken);
        return Result.Success();
    }
}

public sealed class RevokeDeviceCommandHandler : IRequestHandler<RevokeDeviceCommand, Result>
{
    private readonly IAuthSessionService _authSessionService;

    public RevokeDeviceCommandHandler(IAuthSessionService authSessionService) => _authSessionService = authSessionService;

    public async Task<Result> Handle(RevokeDeviceCommand request, CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            return Result.Failure(new Error("User.NotAuthenticated", "User not authenticated", ErrorType.Unauthorized));

        await _authSessionService.RevokeDeviceAsync(request.UserId, request.DeviceId, cancellationToken);
        return Result.Success();
    }
}