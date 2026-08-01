using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Auth;

public sealed class GetMySessionsQueryHandler : IRequestHandler<GetMySessionsQuery, Result<IReadOnlyList<AuthSessionDto>>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetMySessionsQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<IReadOnlyList<AuthSessionDto>>> Handle(GetMySessionsQuery request, CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            return Result.Failure<IReadOnlyList<AuthSessionDto>>(new Error("User.NotAuthenticated", "User not authenticated", ErrorType.Unauthorized));

        var repo = _unitOfWork.Repository<UserSession>();
        var sessions = await repo.GetListBySpecificationAsync(new UserSessionsByUserSpecification(request.UserId), cancellationToken);
        var result = sessions.Select(session => new AuthSessionDto(session.Id, session.DeviceId, session.IpAddress, session.UserAgent, session.IsActive, session.StartedAt, session.EndedAt)).ToList();
        return Result.Success<IReadOnlyList<AuthSessionDto>>(result);
    }
}

public sealed class GetMyDevicesQueryHandler : IRequestHandler<GetMyDevicesQuery, Result<IReadOnlyList<AuthDeviceDto>>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetMyDevicesQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<IReadOnlyList<AuthDeviceDto>>> Handle(GetMyDevicesQuery request, CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            return Result.Failure<IReadOnlyList<AuthDeviceDto>>(new Error("User.NotAuthenticated", "User not authenticated", ErrorType.Unauthorized));

        var repo = _unitOfWork.Repository<UserDevice>();
        var devices = await repo.GetListBySpecificationAsync(new UserDevicesByUserSpecification(request.UserId), cancellationToken);
        var result = devices.Select(device => new AuthDeviceDto(device.Id, device.DeviceId, device.DeviceName, device.DeviceType, device.IsActive, device.LastUsedAt)).ToList();
        return Result.Success<IReadOnlyList<AuthDeviceDto>>(result);
    }
}