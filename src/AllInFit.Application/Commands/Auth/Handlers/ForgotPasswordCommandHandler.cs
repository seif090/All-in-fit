using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Contracts;
using AllInFit.Shared.Result;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Commands.Auth.Handlers;

public sealed class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IEmailSender _emailSender;
    private readonly ISmsSender _smsSender;
    private readonly ILogger<ForgotPasswordCommandHandler> _logger;

    public ForgotPasswordCommandHandler(IUnitOfWork unitOfWork, IEmailSender emailSender, ISmsSender smsSender, ILogger<ForgotPasswordCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _emailSender = emailSender;
        _smsSender = smsSender;
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

        var code = Random.Shared.Next(0, 1_000_000).ToString("D6");
        user.SetOtp(code, DateTime.UtcNow.AddMinutes(15));
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
        {
            await _smsSender.SendAsync(new SmsMessage(user.PhoneNumber, $"Your All In Fit reset code is {code}. It expires in 15 minutes."), cancellationToken);
        }
        else
        {
            await _emailSender.SendAsync(new EmailMessage(user.Email, "All In Fit password reset", $"Your reset code is {code}. It expires in 15 minutes.", IsHtml: false), cancellationToken);
        }

        _logger.LogInformation("Password reset code issued for {Email}", request.Email);
        return Result.Success();
    }
}