using AllInFit.Application.Queries.Auth;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[Authorize]
[Route("api/v{version:apiVersion}/auth/sessions")]
public sealed class SessionsController : ApiControllerBase
{
    private readonly IMediator _mediator;

    public SessionsController(IMediator mediator) => _mediator = mediator;

    [HttpGet]
    public async Task<IActionResult> GetMySessions(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMySessionsQuery(CurrentUserId ?? Guid.Empty), cancellationToken);
        return FromResult(result);
    }
}