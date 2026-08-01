using AllInFit.Application.Commands.Auth;
using AllInFit.Application.Queries.Auth;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[Authorize]
[Route("api/v{version:apiVersion}/auth/devices")]
public sealed class DevicesController : ApiControllerBase
{
    private readonly IMediator _mediator;

    public DevicesController(IMediator mediator) => _mediator = mediator;

    [HttpGet]
    public async Task<IActionResult> GetMyDevices(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMyDevicesQuery(CurrentUserId ?? Guid.Empty), cancellationToken);
        return FromResult(result);
    }

    [HttpDelete("{deviceId}")]
    public async Task<IActionResult> RevokeDevice(string deviceId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new RevokeDeviceCommand(CurrentUserId ?? Guid.Empty, deviceId), cancellationToken);
        return FromResult(result);
    }
}