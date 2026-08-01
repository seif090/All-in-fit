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