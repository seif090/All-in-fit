using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth;

public sealed record LoginCommand(string Email, string Password, string? DeviceId = null, string? DeviceName = null, string? IpAddress = null, string? UserAgent = null) : IRequest<Result<TokenResponse>>;
public sealed record RegisterCommand(string Email, string Password, string? FirstName, string? LastName, string? PhoneNumber, string? DeviceId = null, string? DeviceName = null, string? IpAddress = null, string? UserAgent = null) : IRequest<Result<TokenResponse>>;
public sealed record RefreshTokenCommand(string AccessToken, string RefreshToken) : IRequest<Result<TokenResponse>>;
public sealed record ForgotPasswordCommand(string Email) : IRequest<Result>;
public sealed record ResetPasswordCommand(string Email, string Token, string NewPassword) : IRequest<Result>;
public sealed record VerifyEmailCommand(string Email, string Token) : IRequest<Result>;
public sealed record GoogleLoginCommand(string IdToken, string? DeviceId = null, string? DeviceName = null, string? IpAddress = null, string? UserAgent = null) : IRequest<Result<TokenResponse>>;
public sealed record RequestOtpLoginCommand(string PhoneNumber) : IRequest<Result>;
public sealed record VerifyOtpLoginCommand(string PhoneNumber, string Code, string? DeviceId = null, string? DeviceName = null, string? IpAddress = null, string? UserAgent = null) : IRequest<Result<TokenResponse>>;
public sealed record LogoutAllDevicesCommand(Guid UserId) : IRequest<Result>;
public sealed record RevokeDeviceCommand(Guid UserId, string DeviceId) : IRequest<Result>;