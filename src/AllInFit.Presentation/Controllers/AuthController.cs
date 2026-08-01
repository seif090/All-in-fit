using AllInFit.Application.Commands.Auth;
using AllInFit.Application.DTOs.Auth;
using AllInFit.Presentation.Controllers;
using AllInFit.Presentation.Filters;
using AllInFit.Shared.Constants;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[Route("api/v{version:apiVersion}/auth")]
public sealed class AuthController : ApiControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator) => _mediator = mediator;

    /// <summary>Registers a new user account.</summary>
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(TokenResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register(RegisterRequest request, CancellationToken cancellationToken)
    {
        var command = new RegisterCommand(
            request.Email,
            request.Password,
            request.FirstName,
            request.LastName,
            request.PhoneNumber,
            CurrentDeviceId,
            null,
            CurrentIpAddress,
            CurrentUserAgent);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Authenticates a user and returns an access/refresh token pair.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var command = new LoginCommand(
            request.Email,
            request.Password,
            request.DeviceId,
            request.DeviceName,
            CurrentIpAddress,
            CurrentUserAgent);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Requests an OTP login code for a phone number.</summary>
    [HttpPost("otp/request")]
    [AllowAnonymous]
    public async Task<IActionResult> RequestOtpLogin(OtpRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new RequestOtpLoginCommand(request.PhoneNumber), cancellationToken);
        return FromResult(result);
    }

    /// <summary>Verifies a phone OTP and issues a token pair.</summary>
    [HttpPost("otp/verify")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyOtpLogin(OtpVerifyRequest request, CancellationToken cancellationToken)
    {
        var command = new VerifyOtpLoginCommand(request.PhoneNumber, request.Code, CurrentDeviceId, null, CurrentIpAddress, CurrentUserAgent);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Authenticates a Google identity token.</summary>
    [HttpPost("google")]
    [AllowAnonymous]
    public async Task<IActionResult> GoogleLogin(GoogleLoginRequest request, CancellationToken cancellationToken)
    {
        var command = new GoogleLoginCommand(request.IdToken, request.DeviceId, request.DeviceName, CurrentIpAddress, CurrentUserAgent);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Rotates a refresh token into a fresh token pair.</summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh(RefreshTokenRequest request, CancellationToken cancellationToken)
    {
        var command = new RefreshTokenCommand(request.AccessToken, request.RefreshToken);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Requests a password reset code (email/sms).</summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ForgotPasswordCommand(request.Email), cancellationToken);
        return FromResult(result);
    }

    /// <summary>Resets a password using the reset code.</summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request, CancellationToken cancellationToken)
    {
        var command = new ResetPasswordCommand(request.Email, request.Token, request.NewPassword);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Verifies a user's email address.</summary>
    [HttpPost("verify-email")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyEmail(VerifyEmailRequest request, CancellationToken cancellationToken)
    {
        var command = new VerifyEmailCommand(request.Email, request.Token);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Logs out all devices and sessions for the current user.</summary>
    [HttpPost("logout-all")]
    [Authorize]
    [PermissionAuthorize(Permissions.AuthLogoutAll)]
    public async Task<IActionResult> LogoutAllDevices(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new LogoutAllDevicesCommand(CurrentUserId ?? Guid.Empty), cancellationToken);
        return FromResult(result);
    }
}