$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Application"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Gym Commands =====
Write-File "$base\Commands\Gyms\CreateGymCommand.cs" @'
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Gyms;

public sealed record CreateGymCommand(
    string Name,
    string LegalName,
    string? LogoUrl,
    string? Description,
    string? Website,
    Guid OwnerUserId) : IRequest<Result<Guid>>;

public sealed record UpdateGymCommand(Guid GymId, string Name, string? Description) : IRequest<Result>;

public sealed record DeleteGymCommand(Guid GymId) : IRequest<Result>;
'@

# ===== Gym Queries =====
Write-File "$base\Queries\Gyms\GetGymQuery.cs" @'
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Gyms;

public sealed record GetGymQuery(Guid GymId) : IRequest<Result<GymDto>>;

public sealed record GymDto(
    Guid Id,
    string Name,
    string LegalName,
    string? LogoUrl,
    string? Description,
    bool IsVerified,
    bool IsActive,
    double? Rating,
    int ReviewCount);
'@

# ===== User Queries =====
Write-File "$base\Queries\Users\GetUserQuery.cs" @'
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed record GetUserQuery(Guid UserId) : IRequest<Result<UserDto>>;
public sealed record GetCurrentUserQuery : IRequest<Result<UserDto>>;

public sealed record UserDto(
    Guid Id,
    string Email,
    string? FirstName,
    string? LastName,
    string? PhoneNumber,
    bool IsActive,
    DateTime CreatedAt);
'@

Write-File "$base\Queries\Users\GetUserQueryHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed class GetUserQueryHandler : IRequestHandler<GetUserQuery, Result<UserDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetUserQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<UserDto>> Handle(GetUserQuery request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<UserDto>(new Error("User.NotFound", "User not found"));
    }
}

public sealed class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, Result<UserDto>>
{
    public async Task<Result<UserDto>> Handle(GetCurrentUserQuery request, CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
        return Result.Failure<UserDto>(new Error("User.NotAuthenticated", "User not authenticated"));
    }
}
'@

# ===== MediatR DI Registration =====
Write-File "$base\DependencyInjection.cs" @'
using AllInFit.Application.Behaviors;
using FluentValidation;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace AllInFit.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationLayer(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly);
        });

        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(TransactionBehavior<,>));

        return services;
    }
}
'@

Write-Host "Application layer part 2 generated successfully!"
