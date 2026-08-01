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
    private readonly IAuthSessionService _authSessionService;
    private readonly ILogger<LoginCommandHandler> _logger;

    public LoginCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IAuthSessionService authSessionService,
        ILogger<LoginCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _authSessionService = authSessionService;
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

        await _authSessionService.RecordSignInAsync(user, request.DeviceId, request.DeviceName, request.IpAddress, request.UserAgent, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User {UserId} logged in successfully", user.Id);
        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }
}