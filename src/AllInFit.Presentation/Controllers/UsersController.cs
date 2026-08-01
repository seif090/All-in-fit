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