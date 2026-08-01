$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\ForgotPasswordCommandHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ForgotPasswordCommandHandler> _logger;

    public ForgotPasswordCommandHandler(IUnitOfWork unitOfWork, ILogger<ForgotPasswordCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<Result> Handle(ForgotPasswordCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);

        // Do not disclose whether the account exists
        if (user is null)
        {
            _logger.LogInformation("Password reset requested for unknown email");
            return Result.Success();
        }

        // Generate OTP-style reset code (placeholder for real SMS/Email delivery)
        var code = Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        user.SetOtp(code, DateTime.UtcNow.AddMinutes(15));
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Password reset code issued for {Email}", request.Email);
        return Result.Success();
    }
}
'@

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\ResetPasswordCommandHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class ResetPasswordCommandHandler : IRequestHandler<ResetPasswordCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;

    public ResetPasswordCommandHandler(IUnitOfWork unitOfWork, IPasswordHasher passwordHasher)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
    }

    public async Task<Result> Handle(ResetPasswordCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);
        if (user is null)
            return Result.Failure(new Error("Auth.InvalidResetToken", "Invalid reset request", ErrorType.Unauthorized));

        if (!user.VerifyOtp(request.Token))
            return Result.Failure(new Error("Auth.InvalidResetToken", "Invalid or expired reset code", ErrorType.Unauthorized));

        user.UpdatePassword(_passwordHasher.HashPassword(request.NewPassword));
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success();
    }
}
'@

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\VerifyEmailCommandHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class VerifyEmailCommandHandler : IRequestHandler<VerifyEmailCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;

    public VerifyEmailCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result> Handle(VerifyEmailCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);
        if (user is null)
            return Result.Failure(new Error("Auth.UserNotFound", "User not found", ErrorType.NotFound));

        if (!user.VerifyOtp(request.Token))
            return Result.Failure(new Error("Auth.InvalidVerificationToken", "Invalid verification code", ErrorType.Unauthorized));

        user.VerifyEmail();
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success();
    }
}
'@

Write-Host "generate-auth-4.ps1 complete."

