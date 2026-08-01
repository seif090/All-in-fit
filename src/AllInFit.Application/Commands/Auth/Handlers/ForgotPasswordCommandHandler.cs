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