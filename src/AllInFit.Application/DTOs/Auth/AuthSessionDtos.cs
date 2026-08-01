namespace AllInFit.Application.DTOs.Auth;

public sealed record AuthSessionDto(
    Guid Id,
    string? DeviceId,
    string? IpAddress,
    string? UserAgent,
    bool IsActive,
    DateTime StartedAt,
    DateTime? EndedAt);

public sealed record AuthDeviceDto(
    Guid Id,
    string DeviceId,
    string? DeviceName,
    string? DeviceType,
    bool IsActive,
    DateTime LastUsedAt);