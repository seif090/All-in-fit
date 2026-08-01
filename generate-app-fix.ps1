$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Application"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# Fix TransactionBehavior to use Ports
Write-File "$base\Behaviors\TransactionBehavior.cs" @'
using AllInFit.Application.Ports;
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
        if (typeof(TRequest).Name.EndsWith("Query")) return await next();
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

# Fix Gym command handlers to use Ports
Write-File "$base\Commands\Gyms\CreateGymCommandHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Gyms;

public sealed class CreateGymCommandHandler : IRequestHandler<CreateGymCommand, Result<Guid>>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<Guid>> Handle(CreateGymCommand request, CancellationToken cancellationToken)
    {
        var gym = new Gym(request.Name, request.LegalName, request.LogoUrl, request.Description, request.Website, request.OwnerUserId);
        var repo = _unitOfWork.Repository<Gym>();
        await repo.AddAsync(gym, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(gym.Id);
    }
}

public sealed class UpdateGymCommandHandler : IRequestHandler<UpdateGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    public UpdateGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result> Handle(UpdateGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure(new Error("Gym.NotFound", "Gym not found"));
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}

public sealed class DeleteGymCommandHandler : IRequestHandler<DeleteGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    public DeleteGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result> Handle(DeleteGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure(new Error("Gym.NotFound", "Gym not found"));
        await repo.DeleteAsync(gym);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
'@

# Fix Gym query handler to use Ports
Write-File "$base\Queries\Gyms\GetGymQueryHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Gyms;

public sealed class GetGymQueryHandler : IRequestHandler<GetGymQuery, Result<GymDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetGymQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<GymDto>> Handle(GetGymQuery request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure<GymDto>(new Error("Gym.NotFound", "Gym not found"));
        return Result.Success(new GymDto(gym.Id, gym.Name, gym.LegalName, gym.LogoUrl, gym.Description, gym.IsVerified, gym.IsActive, gym.Rating, gym.ReviewCount));
    }
}
'@

# Fix the Error class to accept 2 args - check the shared kernel
Write-File "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Shared\Result\Error.cs" @'
namespace AllInFit.Shared.Result;

public sealed record Error(string Code, string Message, ErrorType Type = ErrorType.Validation)
{
    public static readonly Error None = new(string.Empty, string.Empty);
    public static readonly Error NullValue = new("Error.NullValue", "Null value was provided");
}

public enum ErrorType
{
    Validation = 0,
    NotFound = 1,
    Conflict = 2,
    Unauthorized = 3,
    Forbidden = 4,
    Internal = 5
}
'@

# Fix the Result class to use the new Error
Write-File "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Shared\Result\Result.cs" @'
namespace AllInFit.Shared.Result;

public class Result
{
    protected Result(bool isSuccess, Error error)
    {
        if (isSuccess && error != Error.None)
            throw new InvalidOperationException("Success result cannot have an error");
        if (!isSuccess && error == Error.None)
            throw new InvalidOperationException("Failure result must have an error");

        IsSuccess = isSuccess;
        Error = error;
    }

    public bool IsSuccess { get; }
    public bool IsFailure => !IsSuccess;
    public Error Error { get; }

    public static Result Success() => new(true, Error.None);
    public static Result<T> Success<T>(T value) => new(value, true, Error.None);
    public static Result Failure(Error error) => new(false, error);
    public static Result<T> Failure<T>(Error error) => new(default, false, error);
}

public sealed class Result<T> : Result
{
    private readonly T? _value;

    public Result(T? value, bool isSuccess, Error error) : base(isSuccess, error)
    {
        _value = value;
    }

    public T Value => IsSuccess
        ? _value!
        : throw new InvalidOperationException("Cannot access value of a failed result");
}
'@

Write-Host "Application layer fixes applied!"
