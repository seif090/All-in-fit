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