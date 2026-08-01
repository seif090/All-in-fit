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