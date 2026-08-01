using AllInFit.Application.Commands.Auth;
using FluentValidation;

namespace AllInFit.Application.Validators;

public sealed class LoginCommandValidator : AbstractValidator<LoginCommand>
{
    public LoginCommandValidator()
    {
        RuleFor(command => command.Email).NotEmpty().EmailAddress();
        RuleFor(command => command.Password).NotEmpty().MinimumLength(8);
        RuleFor(command => command.DeviceId).MaximumLength(128).When(command => command.DeviceId is not null);
        RuleFor(command => command.DeviceName).MaximumLength(128).When(command => command.DeviceName is not null);
    }
}

public sealed class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(command => command.Email).NotEmpty().EmailAddress();
        RuleFor(command => command.Password)
            .NotEmpty()
            .MinimumLength(12)
            .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
            .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
            .Matches("[0-9]").WithMessage("Password must contain at least one digit.")
            .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character.");
        RuleFor(command => command.FirstName).MaximumLength(100).When(command => command.FirstName is not null);
        RuleFor(command => command.LastName).MaximumLength(100).When(command => command.LastName is not null);
        RuleFor(command => command.PhoneNumber)
            .Matches("^\\+?[1-9]\\d{7,14}$")
            .When(command => !string.IsNullOrWhiteSpace(command.PhoneNumber))
            .WithMessage("Phone number must be in international E.164 format.");
    }
}

public sealed class RefreshTokenCommandValidator : AbstractValidator<RefreshTokenCommand>
{
    public RefreshTokenCommandValidator()
    {
        RuleFor(command => command.AccessToken).NotEmpty();
        RuleFor(command => command.RefreshToken).NotEmpty();
    }
}

public sealed class ForgotPasswordCommandValidator : AbstractValidator<ForgotPasswordCommand>
{
    public ForgotPasswordCommandValidator()
    {
        RuleFor(command => command.Email).NotEmpty().EmailAddress();
    }
}

public sealed class ResetPasswordCommandValidator : AbstractValidator<ResetPasswordCommand>
{
    public ResetPasswordCommandValidator()
    {
        RuleFor(command => command.Email).NotEmpty().EmailAddress();
        RuleFor(command => command.Token).NotEmpty();
        RuleFor(command => command.NewPassword).NotEmpty().MinimumLength(12);
    }
}

public sealed class VerifyEmailCommandValidator : AbstractValidator<VerifyEmailCommand>
{
    public VerifyEmailCommandValidator()
    {
        RuleFor(command => command.Email).NotEmpty().EmailAddress();
        RuleFor(command => command.Token).NotEmpty();
    }
}