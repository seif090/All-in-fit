$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

# ============ Base Controller with Result-to-HTTP mapping ============
Write-File "$root\AllInFit.Presentation\Controllers\ApiControllerBase.cs" @'
using AllInFit.Shared.Result;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[ApiController]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    protected IActionResult FromResult(Result result)
    {
        if (result.IsSuccess)
            return Ok(new { success = true });

        return ToError(result.Error);
    }

    protected IActionResult FromResult<T>(Result<T> result)
    {
        if (result.IsSuccess)
            return Ok(result.Value);

        return ToError(result.Error);
    }

    private IActionResult ToError(Error error)
    {
        var payload = new
        {
            success = false,
            error = new
            {
                code = error.Code,
                message = error.Message
            }
        };

        return error.Type switch
        {
            ErrorType.NotFound => NotFound(payload),
            ErrorType.Conflict => Conflict(payload),
            ErrorType.Unauthorized => Unauthorized(payload),
            ErrorType.Forbidden => StatusCode(StatusCodes.Status403Forbidden, payload),
            ErrorType.Validation => BadRequest(payload),
            _ => BadRequest(payload)
        };
    }

    protected Guid? CurrentUserId =>
        Guid.TryParse(User.FindFirst("sub")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value,
            out var id) ? id : null;
}
'@

# ============ Auth Controller ============
Write-File "$root\AllInFit.Presentation\Controllers\AuthController.cs" @'
using AllInFit.Application.Commands.Auth;
using AllInFit.Application.DTOs.Auth;
using AllInFit.Presentation.Controllers;
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
            request.PhoneNumber);
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
            request.DeviceName);
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
}
'@

Write-Host "generate-auth-controller.ps1 complete."

