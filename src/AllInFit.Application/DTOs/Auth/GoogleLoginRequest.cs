namespace AllInFit.Application.DTOs.Auth;

public sealed record GoogleLoginRequest(string IdToken, string? DeviceId = null, string? DeviceName = null);