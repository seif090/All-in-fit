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