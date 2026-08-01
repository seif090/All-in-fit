using AllInFit.Shared.Result;
using Microsoft.AspNetCore.Mvc;

namespace AllInFit.Presentation.Controllers;

[ApiController]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    protected IActionResult FromResult(Result result)
    {
        if (result.IsSuccess)
            return Ok(new { success = true });

        return ToError(result.Error);
    }

    protected IActionResult FromResult<T>(Result<T> result)
    {
        if (result.IsSuccess)
            return Ok(result.Value);

        return ToError(result.Error);
    }

    private IActionResult ToError(Error error)
    {
        var payload = new
        {
            success = false,
            error = new
            {
                code = error.Code,
                message = error.Message
            }
        };

        return error.Type switch
        {
            ErrorType.NotFound => NotFound(payload),
            ErrorType.Conflict => Conflict(payload),
            ErrorType.Unauthorized => Unauthorized(payload),
            ErrorType.Forbidden => StatusCode(StatusCodes.Status403Forbidden, payload),
            ErrorType.Validation => BadRequest(payload),
            _ => BadRequest(payload)
        };
    }

    protected Guid? CurrentUserId =>
        Guid.TryParse(User.FindFirst("sub")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value,
            out var id) ? id : null;
}