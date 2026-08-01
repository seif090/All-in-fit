using AllInFit.Application.Commands.Gyms;
using FluentValidation;

namespace AllInFit.Application.Validators;

public sealed class CreateGymCommandValidator : AbstractValidator<CreateGymCommand>
{
    public CreateGymCommandValidator()
    {
        RuleFor(command => command.Name).NotEmpty().MaximumLength(200);
        RuleFor(command => command.LegalName).NotEmpty().MaximumLength(200);
        RuleFor(command => command.LogoUrl).MaximumLength(500).When(command => command.LogoUrl is not null);
        RuleFor(command => command.Description).MaximumLength(4000).When(command => command.Description is not null);
        RuleFor(command => command.Website).MaximumLength(2048).When(command => command.Website is not null);
        RuleFor(command => command.OwnerUserId).NotEmpty();
    }
}

public sealed class UpdateGymCommandValidator : AbstractValidator<UpdateGymCommand>
{
    public UpdateGymCommandValidator()
    {
        RuleFor(command => command.GymId).NotEmpty();
        RuleFor(command => command.Name).NotEmpty().MaximumLength(200);
        RuleFor(command => command.Description).MaximumLength(4000).When(command => command.Description is not null);
    }
}

public sealed class DeleteGymCommandValidator : AbstractValidator<DeleteGymCommand>
{
    public DeleteGymCommandValidator()
    {
        RuleFor(command => command.GymId).NotEmpty();
    }
}