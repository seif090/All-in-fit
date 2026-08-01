using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Auth;

public sealed class AuthSessionService : IAuthSessionService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuthSessionService> _logger;

    public AuthSessionService(IUnitOfWork unitOfWork, ILogger<AuthSessionService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task RecordSignInAsync(User user, string? deviceId, string? deviceName, string? ipAddress, string? userAgent, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(deviceId))
        {
            var deviceRepo = _unitOfWork.Repository<UserDevice>();
            var device = await deviceRepo.GetBySpecificationAsync(new UserDevicesByUserAndDeviceSpecification(user.Id, deviceId), cancellationToken);
            if (device is null)
            {
                await deviceRepo.AddAsync(new UserDevice
                {
                    UserId = user.Id,
                    DeviceId = deviceId,
                    DeviceName = deviceName,
                    IsActive = true,
                    LastUsedAt = DateTime.UtcNow
                }, cancellationToken);
            }
            else
            {
                device.DeviceName = deviceName ?? device.DeviceName;
                device.IsActive = true;
                device.LastUsedAt = DateTime.UtcNow;
                await deviceRepo.UpdateAsync(device);
            }
        }

        var sessionRepo = _unitOfWork.Repository<UserSession>();
        await sessionRepo.AddAsync(new UserSession
        {
            UserId = user.Id,
            DeviceId = deviceId,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            IsActive = true,
            StartedAt = DateTime.UtcNow
        }, cancellationToken);
    }

    public async Task LogoutAllDevicesAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        await RevokeTokensAsync(userId, null, cancellationToken);
        await EndSessionsAsync(userId, null, cancellationToken);
        await DisableDevicesAsync(userId, null, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Logged out all devices for user {UserId}", userId);
    }

    public async Task RevokeDeviceAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default)
    {
        await RevokeTokensAsync(userId, deviceId, cancellationToken);
        await EndSessionsAsync(userId, deviceId, cancellationToken);
        await DisableDevicesAsync(userId, deviceId, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Revoked device {DeviceId} for user {UserId}", deviceId, userId);
    }

    private async Task RevokeTokensAsync(Guid userId, string? deviceId, CancellationToken cancellationToken)
    {
        var tokenRepo = _unitOfWork.Repository<RefreshToken>();
        var tokens = deviceId is null
            ? await tokenRepo.GetListBySpecificationAsync(new RefreshTokensByUserSpecification(userId), cancellationToken)
            : await tokenRepo.GetListBySpecificationAsync(new RefreshTokensByUserAndDeviceSpecification(userId, deviceId), cancellationToken);

        foreach (var token in tokens.Where(token => token.IsActive))
            token.Revoke("Signed out");
    }

    private async Task EndSessionsAsync(Guid userId, string? deviceId, CancellationToken cancellationToken)
    {
        var sessionRepo = _unitOfWork.Repository<UserSession>();
        var sessions = deviceId is null
            ? await sessionRepo.GetListBySpecificationAsync(new UserSessionsByUserSpecification(userId), cancellationToken)
            : await sessionRepo.GetListBySpecificationAsync(new UserSessionsByUserAndDeviceSpecification(userId, deviceId), cancellationToken);

        foreach (var session in sessions.Where(session => session.IsActive))
            session.End();
    }

    private async Task DisableDevicesAsync(Guid userId, string? deviceId, CancellationToken cancellationToken)
    {
        var deviceRepo = _unitOfWork.Repository<UserDevice>();
        var devices = deviceId is null
            ? await deviceRepo.GetListBySpecificationAsync(new UserDevicesByUserSpecification(userId), cancellationToken)
            : await deviceRepo.GetListBySpecificationAsync(new UserDevicesByUserAndDeviceSpecification(userId, deviceId), cancellationToken);

        foreach (var device in devices.Where(device => device.IsActive))
            device.IsActive = false;
    }
}