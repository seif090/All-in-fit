$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Application"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== MediatR Pipelines =====
Write-File "$base\Behaviors\ValidationBehavior.cs" @'
using FluentValidation;
using MediatR;

namespace AllInFit.Application.Behaviors;

public sealed class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (!_validators.Any()) return await next();

        var context = new ValidationContext<TRequest>(request);
        var failures = _validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f is not null)
            .ToList();

        if (failures.Count != 0)
            throw new ValidationException(failures);

        return await next();
    }
}
'@

Write-File "$base\Behaviors\LoggingBehavior.cs" @'
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Behaviors;

public sealed class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling {RequestType} at {Time}", typeof(TRequest).Name, DateTime.UtcNow);
        var response = await next();
        _logger.LogInformation("Handled {RequestType} at {Time}", typeof(TRequest).Name, DateTime.UtcNow);
        return response;
    }
}
'@

Write-File "$base\Behaviors\TransactionBehavior.cs" @'
using AllInFit.Persistence.Repositories;
using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Behaviors;

public sealed class TransactionBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<TransactionBehavior<TRequest, TResponse>> _logger;

    public TransactionBehavior(IUnitOfWork unitOfWork, ILogger<TransactionBehavior<TRequest, TResponse>> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (typeof(TRequest).Name.EndsWith("Query"))
            return await next();

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            var response = await next();
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);
            return response;
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            _logger.LogError(ex, "Transaction failed for {RequestType}", typeof(TRequest).Name);
            throw;
        }
    }
}
'@

# ===== DTOs =====
Write-File "$base\DTOs\Auth\LoginRequest.cs" @'
namespace AllInFit.Application.DTOs.Auth;

public record LoginRequest(string Email, string Password, string? DeviceId = null, string? DeviceName = null);

public record RegisterRequest(string Email, string Password, string? FirstName, string? LastName, string? PhoneNumber);

public record TokenResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt);

public record RefreshTokenRequest(string AccessToken, string RefreshToken);

public record ForgotPasswordRequest(string Email);

public record ResetPasswordRequest(string Email, string Token, string NewPassword);

public record VerifyEmailRequest(string Email, string Token);

public record OtpRequest(string PhoneNumber);

public record OtpVerifyRequest(string PhoneNumber, string Code);
'@

Write-File "$base\DTOs\Common\PaginationRequest.cs" @'
namespace AllInFit.Application.DTOs.Common;

public record PaginationRequest(int Page = 1, int PageSize = 10);

public record PagedResponse<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);
'@

# ===== CQRS - Auth Commands =====
Write-File "$base\Commands\Auth\LoginCommand.cs" @'
using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth;

public sealed record LoginCommand(string Email, string Password, string? DeviceId = null, string? DeviceName = null)
    : IRequest<Result<TokenResponse>>;

public sealed record RegisterCommand(string Email, string Password, string? FirstName, string? LastName, string? PhoneNumber)
    : IRequest<Result<TokenResponse>>;

public sealed record RefreshTokenCommand(string AccessToken, string RefreshToken)
    : IRequest<Result<TokenResponse>>;

public sealed record ForgotPasswordCommand(string Email)
    : IRequest<Result>;

public sealed record ResetPasswordCommand(string Email, string Token, string NewPassword)
    : IRequest<Result>;

public sealed record VerifyEmailCommand(string Email, string Token)
    : IRequest<Result>;
'@

Write-File "$base\Commands\Auth\LoginCommandHandler.cs" @'
using AllInFit.Application.DTOs.Auth;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Auth;

public sealed class LoginCommandHandler : IRequestHandler<LoginCommand, Result<TokenResponse>>
{
    public async Task<Result<TokenResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        // Will be implemented with JWT auth service in Infrastructure layer
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
'@

# ===== CQRS - User Queries =====
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
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed class GetUserQueryHandler : IRequestHandler<GetUserQuery, Result<UserDto>>
{
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

# ===== CQRS - Gym Commands =====
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

Write-File "$base\Commands\Gyms\CreateGymCommandHandler.cs" @'
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Persistence.Repositories;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Gyms;

public sealed class CreateGymCommandHandler : IRequestHandler<CreateGymCommand, Result<Guid>>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateGymCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<Guid>> Handle(CreateGymCommand request, CancellationToken cancellationToken)
    {
        var gym = new Gym(
            request.Name,
            request.LegalName,
            request.LogoUrl,
            request.Description,
            request.Website,
            request.OwnerUserId);

        var repo = _unitOfWork.Repository<Gym>();
        await repo.AddAsync(gym, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(gym.Id);
    }
}

public sealed class UpdateGymCommandHandler : IRequestHandler<UpdateGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;

    public UpdateGymCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result> Handle(UpdateGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null)
            return Result.Failure(new Error("Gym.NotFound", "Gym not found"));

        // Gym has private setters, so we'd use a domain method
        // gym.Name = request.Name; etc.
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}

public sealed class DeleteGymCommandHandler : IRequestHandler<DeleteGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;

    public DeleteGymCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result> Handle(DeleteGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null)
            return Result.Failure(new Error("Gym.NotFound", "Gym not found"));

        await repo.DeleteAsync(gym);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
'@

# ===== CQRS - User Queries =====
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

Write-File "$base\Queries\Gyms\GetGymQueryHandler.cs" @'
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Persistence.Repositories;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Gyms;

public sealed class GetGymQueryHandler : IRequestHandler<GetGymQuery, Result<GymDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetGymQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<GymDto>> Handle(GetGymQuery request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null)
            return Result.Failure<GymDto>(new Error("Gym.NotFound", "Gym not found"));

        return Result.Success(new GymDto(
            gym.Id, gym.Name, gym.LegalName, gym.LogoUrl,
            gym.Description, gym.IsVerified, gym.IsActive,
            gym.Rating, gym.ReviewCount));
    }
}
'@

# ===== CQRS - Product Queries =====
Write-File "$base\Queries\Marketplace\GetProductsQuery.cs" @'
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Marketplace;

public sealed record GetProductsQuery(
    string? SearchTerm =
