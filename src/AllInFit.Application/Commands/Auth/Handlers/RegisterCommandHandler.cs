using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Contracts;
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
    private readonly IEmailSender _emailSender;
    private readonly IAuthSessionService _authSessionService;
    private readonly ILogger<RegisterCommandHandler> _logger;

    public RegisterCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IEmailSender emailSender,
        IAuthSessionService authSessionService,
        ILogger<RegisterCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _emailSender = emailSender;
        _authSessionService = authSessionService;
        _logger = logger;
    }

    public async Task<Result<TokenResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var existing = await repo.GetBySpecificationAsync(new UserByEmailSpecification(request.Email), cancellationToken);
        if (existing is not null)
            return Result.Failure<TokenResponse>(new Error("Auth.EmailInUse", "Email is already registered", ErrorType.Conflict));

        var passwordHash = _passwordHasher.HashPassword(request.Password);
        var user = new User(
            request.Email,
            request.FirstName ?? string.Empty,
            request.LastName ?? string.Empty,
            passwordHash);
        user.UpdateProfile(
            request.FirstName ?? string.Empty,
            request.LastName ?? string.Empty,
            request.PhoneNumber,
            null,
            null,
            Gender.Other);

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

        user.SetOtp(GenerateCode(), DateTime.UtcNow.AddMinutes(15));
        await _authSessionService.RecordSignInAsync(user, request.DeviceId, request.DeviceName, request.IpAddress, request.UserAgent, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _emailSender.SendAsync(new EmailMessage(
            user.Email,
            "Verify your All In Fit email",
            $"Your verification code is {user.OtpCode}. It expires in 15 minutes.",
            IsHtml: false),
            cancellationToken);

        _logger.LogInformation("New user registered: {Email} (Id: {UserId})", user.Email, user.Id);
        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }

    private static string GenerateCode() => Random.Shared.Next(0, 1_000_000).ToString("D6");
}