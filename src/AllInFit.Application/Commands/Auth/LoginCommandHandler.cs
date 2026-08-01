using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth;

public sealed class LoginCommandHandler : IRequestHandler<LoginCommand, Result<TokenResponse>>
{
    public async Task<Result<TokenResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<TokenResponse>(new Error("Auth.Login", "Invalid credentials"));
    }
}

public sealed class RegisterCommandHandler : IRequestHandler<RegisterCommand, Result<TokenResponse>>
{
    public async Task<Result<TokenResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<TokenResponse>(new Error("Auth.Register", "Registration not yet implemented"));
    }
}

public sealed class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, Result<TokenResponse>>
{
    public async Task<Result<TokenResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<TokenResponse>(new Error("Auth.Refresh", "Refresh not yet implemented"));
    }
}

public sealed class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, Result>
{
    public async Task<Result> Handle(ForgotPasswordCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Success();
    }
}

public sealed class ResetPasswordCommandHandler : IRequestHandler<ResetPasswordCommand, Result>
{
    public async Task<Result> Handle(ResetPasswordCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Success();
    }
}

public sealed class VerifyEmailCommandHandler : IRequestHandler<VerifyEmailCommand, Result>
{
    public async Task<Result> Handle(VerifyEmailCommand request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Success();
    }
}