using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class GoogleLoginCommandHandler : IRequestHandler<GoogleLoginCommand, Result<TokenResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IGoogleIdentityVerifier _googleIdentityVerifier;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IAuthSessionService _authSessionService;

    public GoogleLoginCommandHandler(IUnitOfWork unitOfWork, IGoogleIdentityVerifier googleIdentityVerifier, IPasswordHasher passwordHasher, ITokenService tokenService, IAuthSessionService authSessionService)
    {
        _unitOfWork = unitOfWork;
        _googleIdentityVerifier = googleIdentityVerifier;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _authSessionService = authSessionService;
    }

    public async Task<Result<TokenResponse>> Handle(GoogleLoginCommand request, CancellationToken cancellationToken)
    {
        var googleProfile = await _googleIdentityVerifier.VerifyAsync(request.IdToken, cancellationToken);
        if (googleProfile is null || !googleProfile.EmailVerified)
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidGoogleToken", "Invalid Google identity token", ErrorType.Unauthorized));

        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByEmailSpecification(googleProfile.Email), cancellationToken);

        if (user is null)
        {
            var tempPassword = _passwordHasher.HashPassword(Guid.NewGuid().ToString("N"));
            user = new User(
                googleProfile.Email,
                googleProfile.GivenName ?? string.Empty,
                googleProfile.FamilyName ?? string.Empty,
                tempPassword);
            user.SetGoogleAccount(googleProfile.Subject);
            user.UpdateProfile(googleProfile.GivenName ?? string.Empty, googleProfile.FamilyName ?? string.Empty, null, null, null, Gender.Other);
            await repo.AddAsync(user, cancellationToken);
        }
        else
        {
            if (!user.IsActive)
                return Result.Failure<TokenResponse>(new Error("Auth.Inactive", "Account is deactivated", ErrorType.Forbidden));

            if (!string.IsNullOrWhiteSpace(user.GoogleId) && !string.Equals(user.GoogleId, googleProfile.Subject, StringComparison.Ordinal))
                return Result.Failure<TokenResponse>(new Error("Auth.GoogleLinkedToAnotherAccount", "Google account is linked to another user", ErrorType.Conflict));

            if (string.IsNullOrWhiteSpace(user.GoogleId))
                user.SetGoogleAccount(googleProfile.Subject);

            user.UpdateProfile(googleProfile.GivenName ?? user.FirstName, googleProfile.FamilyName ?? user.LastName, user.PhoneNumber, user.Bio, user.DateOfBirth, user.Gender);
        }

        var pair = _tokenService.GenerateTokenPair(user);
        var tokenRepo = _unitOfWork.Repository<RefreshToken>();
        await tokenRepo.AddAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = pair.RefreshToken,
            DeviceId = request.DeviceId,
            ExpiresAt = pair.RefreshTokenExpiresAt
        }, cancellationToken);

        await _authSessionService.RecordSignInAsync(user, request.DeviceId, request.DeviceName, request.IpAddress, request.UserAgent, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(new TokenResponse(pair.AccessToken, pair.RefreshToken, pair.AccessTokenExpiresAt));
    }
}