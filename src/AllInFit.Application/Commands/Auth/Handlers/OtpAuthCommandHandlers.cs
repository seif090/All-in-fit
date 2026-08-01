using AllInFit.Application.DTOs.Auth;
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Contracts;
using AllInFit.Shared.Result;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class RequestOtpLoginCommandHandler : IRequestHandler<RequestOtpLoginCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IEmailSender _emailSender;
    private readonly ISmsSender _smsSender;
    private readonly ILogger<RequestOtpLoginCommandHandler> _logger;

    public RequestOtpLoginCommandHandler(IUnitOfWork unitOfWork, IEmailSender emailSender, ISmsSender smsSender, ILogger<RequestOtpLoginCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _emailSender = emailSender;
        _smsSender = smsSender;
        _logger = logger;
    }

    public async Task<Result> Handle(RequestOtpLoginCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByPhoneSpecification(request.PhoneNumber), cancellationToken);
        if (user is null)
        {
            _logger.LogInformation("OTP login requested for unknown phone");
            return Result.Success();
        }

        var code = Random.Shared.Next(0, 1_000_000).ToString("D6");
        user.SetOtp(code, DateTime.UtcNow.AddMinutes(10));
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
        {
            await _smsSender.SendAsync(new SmsMessage(user.PhoneNumber, $"Your All In Fit login code is {code}. It expires in 10 minutes."), cancellationToken);
        }
        else
        {
            await _emailSender.SendAsync(new EmailMessage(user.Email, "All In Fit login code", $"Your login code is {code}. It expires in 10 minutes.", IsHtml: false), cancellationToken);
        }

        return Result.Success();
    }
}

public sealed class VerifyOtpLoginCommandHandler : IRequestHandler<VerifyOtpLoginCommand, Result<TokenResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITokenService _tokenService;
    private readonly IAuthSessionService _authSessionService;

    public VerifyOtpLoginCommandHandler(IUnitOfWork unitOfWork, ITokenService tokenService, IAuthSessionService authSessionService)
    {
        _unitOfWork = unitOfWork;
        _tokenService = tokenService;
        _authSessionService = authSessionService;
    }

    public async Task<Result<TokenResponse>> Handle(VerifyOtpLoginCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByPhoneSpecification(request.PhoneNumber), cancellationToken);
        if (user is null || !user.IsActive)
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidOtp", "Invalid OTP login request", ErrorType.Unauthorized));

        if (!user.VerifyOtp(request.Code))
            return Result.Failure<TokenResponse>(new Error("Auth.InvalidOtp", "Invalid or expired OTP", ErrorType.Unauthorized));

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