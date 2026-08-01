$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\LoginCommandHandler.cs" @'
using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class LoginCommandHandler : IRequestHandler<LoginCommand, Result<TokenResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly ILogger<LoginCommandHandler> _logger;

    public LoginCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        ILogger<LoginCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<Result<TokenResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);
        if (user is null)
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidCredentials", "Invalid email or password", ErrorType.Unauthorized));

        if (!user.IsActive)
            return Result.Failure<TokenResponse>(new Error("Auth.Inactive", "Account is deactivated", ErrorType.Forbidden));

        if (user.IsLockedOut && (user.LockoutEnd is null || user.LockoutEnd > DateTime.UtcNow))
            return Result.Failure<TokenResponse>(new Error("Auth.LockedOut", "Account is temporarily locked", ErrorType.Forbidden));

        if (!_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            user.RecordFailedLogin();
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            _logger.LogWarning("Failed login attempt for {Email}", request.Email);
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidCredentials", "Invalid email or password", ErrorType.Unauthorized));
        }

        user.RecordLogin();

        // Persist refresh token for rotation + device tracking
        var pair = _tokenService.GenerateTokenPair(user);
        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            Token = pair.RefreshToken,
            DeviceId = request.DeviceId,
            ExpiresAt = pair.RefreshTokenExpiresAt
        };
        var tokenRepo = _unitOfWork.Repository<RefreshToken>();
        await tokenRepo.AddAsync(refreshToken, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User {UserId} logged in successfully", user.Id);
        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }
}
'@

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\RegisterCommandHandler.cs" @'
using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Constants;
using AllInFit.Shared.Result;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class RegisterCommandHandler : IRequestHandler<RegisterCommand, Result<TokenResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly ILogger<RegisterCommandHandler> _logger;

    public RegisterCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        ILogger<RegisterCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<Result<TokenResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var existing = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);
        if (existing is not null)
            return Result.Failure<TokenResponse>(new Error("Auth.EmailInUse", "Email is already registered", ErrorType.Conflict));

        var passwordHash = _passwordHasher.HashPassword(request.Password);
        var user = new User(request.Email, request.FirstName ?? string.Empty, request.LastName ?? string.Empty, passwordHash)
        {
            PhoneNumber = request.PhoneNumber
        };

        // Assign default User role
        var roleRepo = _unitOfWork.Repository<Role>();
        var userRole = await roleRepo.GetBySpecificationAsync(new RoleByNameSpecification(Roles.User), cancellationToken);
        if (userRole is not null)
            user.AddRole(userRole);

        await repo.AddAsync(user, cancellationToken);

        var pair = _tokenService.GenerateTokenPair(user);
        var tokenRepo = _unitOfWork.Repository<RefreshToken>();
        await tokenRepo.AddAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = pair.RefreshToken,
            ExpiresAt = pair.RefreshTokenExpiresAt
        }, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("New user registered: {Email} (Id: {UserId})", user.Email, user.Id);
        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }
}
'@

Write-File "$root\AllInFit.Application\Commands\Auth\Handlers\RefreshTokenCommandHandler.cs" @'
using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, Result<TokenResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITokenService _tokenService;

    public RefreshTokenCommandHandler(IUnitOfWork unitOfWork, ITokenService tokenService)
    {
        _unitOfWork = unitOfWork;
        _tokenService = tokenService;
    }

    public async Task<Result<TokenResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var tokenRepo = _unitOfWork.Repository<RefreshToken>();
        var refreshToken = await tokenRepo.GetBySpecificationAsync(new ActiveRefreshTokenSpecification(request.RefreshToken), cancellationToken);
        if (refreshToken is null)
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidRefreshToken", "Refresh token is invalid or expired", ErrorType.Unauthorized));

        // Refresh token rotation: revoke the old token, issue a new one
        var userRepo = _unitOfWork.Repository<User>();
        var user = await userRepo.GetBySpecificationAsync(new UserByIdSpecification(refreshToken.UserId), cancellationToken);
        if (user is null || !user.IsActive)
            return Result.Failure<TokenResponse>(new Error("Auth.UserNotFound", "User account not found or inactive", ErrorType.Unauthorized));

        var pair = _tokenService.GenerateTokenPair(user);

        refreshToken.MarkAsUsed();
        refreshToken.Revoke("Rotated", pair.RefreshToken);

        await tokenRepo.AddAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = pair.RefreshToken,
            DeviceId = refreshToken.DeviceId,
            ExpiresAt = pair.RefreshTokenExpiresAt
        }, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }
}
'@

Write-Host "generate-auth-3.ps1 complete."

