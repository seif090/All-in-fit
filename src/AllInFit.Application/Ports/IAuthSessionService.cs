using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Application.Ports;

public interface IAuthSessionService
{
    Task RecordSignInAsync(User user, string? deviceId, string? deviceName, string? ipAddress, string? userAgent, CancellationToken cancellationToken = default);
    Task LogoutAllDevicesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task RevokeDeviceAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default);
}