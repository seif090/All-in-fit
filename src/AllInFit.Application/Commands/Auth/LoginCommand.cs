using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth;

public sealed record LoginCommand(string Email, string Password, string? DeviceId = null, string? DeviceName = null) : IRequest<Result<TokenResponse>>;
public sealed record RegisterCommand(string Email, string Password, string? FirstName, string? LastName, string? PhoneNumber) : IRequest<Result<TokenResponse>>;
public sealed record RefreshTokenCommand(string AccessToken, string RefreshToken) : IRequest<Result<TokenResponse>>;
public sealed record ForgotPasswordCommand(string Email) : IRequest<Result>;
public sealed record ResetPasswordCommand(string Email, string Token, string NewPassword) : IRequest<Result>;
public sealed record VerifyEmailCommand(string Email, string Token) : IRequest<Result>;