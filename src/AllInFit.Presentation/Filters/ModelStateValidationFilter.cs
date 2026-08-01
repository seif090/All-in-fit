using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace AllInFit.Presentation.Filters;

public sealed class ModelStateValidationFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        if (context.ModelState.IsValid)
            return;

        var errors = context.ModelState
            .Where(entry => entry.Value?.Errors.Count > 0)
            .SelectMany(entry => entry.Value!.Errors.Select(error => new
            {
                field = entry.Key,
                message = error.ErrorMessage
            }))
            .ToArray();

        var payload = new
        {
            success = false,
            error = new
            {
                code = "ValidationError",
                message = "One or more validation failures occurred.",
                details = errors
            }
        };

        context.Result = new BadRequestObjectResult(payload);
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
    }
}