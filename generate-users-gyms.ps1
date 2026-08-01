$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

# ===== Functional User query handlers (replaces failure stubs) =====
Write-File "$root\AllInFit.Application\Queries\Users\GetUserQueryHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed class GetUserQueryHandler : IRequestHandler<GetUserQuery, Result<UserDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetUserQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<UserDto>> Handle(GetUserQuery request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByIdSpecification(request.UserId), cancellationToken);
        if (user is null) return Result.Failure<UserDto>(new Error("User.NotFound", "User not found", ErrorType.NotFound));

        return Result.Success(new UserDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.PhoneNumber,
            user.IsActive,
            user.CreatedAt));
    }
}
'@

Write-File "$root\AllInFit.Application\Queries\Users\GetCurrentUserQueryHandler.cs" @'
using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, Result<UserDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetCurrentUserQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<UserDto>> Handle(GetCurrentUserQuery request, CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            return Result.Failure<UserDto>(new Error("User.NotAuthenticated", "User not authenticated", ErrorType.Unauthorized));

        var repo = _unitOfWork.Repository<User>();
        var user = await repo.GetBySpecificationAsync(new UserByIdSpecification(request.UserId), cancellationToken);
        if (user is null) return Result.Failure<UserDto>(new Error("User.NotFound", "User not found", ErrorType.NotFound));

        return Result.Success(new UserDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.PhoneNumber,
            user.IsActive,
            user.CreatedAt));
    }
}
'@

# ===== GetCurrentUserQuery now carries UserId (injected by controller) =====
Write-File "$root\AllInFit.Application\Queries\Users\GetUserQuery.cs" @'
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Users;

public sealed record GetUserQuery(Guid UserId) : IRequest<Result<UserDto>>;
public sealed record GetCurrentUserQuery(Guid UserId) : IRequest<Result<UserDto>>;

public sealed record UserDto(
    Guid Id,
    string Email,
    string? FirstName,
    string? LastName,
    string? PhoneNumber,
    bool IsActive,
    DateTime CreatedAt);
'@

# ===== Users Controller =====
Write-File "$root\AllInFit.Presentation\Controllers\UsersController.cs" @'
using AllInFit.Application.Queries.Users;
using AllInFit.Presentation.Controllers;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[Authorize]
[Route("api/v{version:apiVersion}/users")]
public sealed class UsersController : ApiControllerBase
{
    private readonly IMediator _mediator;
    public UsersController(IMediator mediator) => _mediator = mediator;

    /// <summary>Returns the currently authenticated user's profile.</summary>
    [HttpGet("me")]
    public async Task<IActionResult> GetMe(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetCurrentUserQuery(CurrentUserId ?? Guid.Empty), cancellationToken);
        return FromResult(result);
    }

    /// <summary>Returns a user profile by id.</summary>
    [HttpGet("{userId:guid}")]
    public async Task<IActionResult> GetById(Guid userId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetUserQuery(userId), cancellationToken);
        return FromResult(result);
    }
}
'@

# ===== Gyms Controller =====
Write-File "$root\AllInFit.Presentation\Controllers\GymsController.cs" @'
using AllInFit.Application.Commands.Gyms;
using AllInFit.Application.Queries.Gyms;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Presentation.Controllers;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[Authorize]
[Route("api/v{version:apiVersion}/gyms")]
public sealed class GymsController : ApiControllerBase
{
    private readonly IMediator _mediator;
    public GymsController(IMediator mediator) => _mediator = mediator;

    /// <summary>Returns a gym by id.</summary>
    [HttpGet("{gymId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(Guid gymId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetGymQuery(gymId), cancellationToken);
        return FromResult(result);
    }

    /// <summary>Creates a new gym.</summary>
    [HttpPost]
    public async Task<IActionResult> Create(CreateGymRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateGymCommand(
            request.Name,
            request.LegalName,
            request.LogoUrl,
            request.Description,
            request.Website,
            CurrentUserId ?? request.OwnerUserId);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Updates a gym.</summary>
    [HttpPut("{gymId:guid}")]
    public async Task<IActionResult> Update(Guid gymId, UpdateGymRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateGymCommand(gymId, request.Name, request.Description);
        var result = await _mediator.Send(command, cancellationToken);
        return FromResult(result);
    }

    /// <summary>Deletes a gym.</summary>
    [HttpDelete("{gymId:guid}")]
    public async Task<IActionResult> Delete(Guid gymId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteGymCommand(gymId), cancellationToken);
        return FromResult(result);
    }
}

public sealed record CreateGymRequest(
    string Name,
    string LegalName,
    string? LogoUrl = null,
    string? Description = null,
    string? Website = null,
    Guid OwnerUserId = default);

public sealed record UpdateGymRequest(string Name, string? Description = null);
'@

Write-Host "generate-users-gyms.ps1 complete."

