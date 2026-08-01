using AllInFit.Shared.Constants;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace AllInFit.Presentation.Filters;

public sealed class PermissionAuthorizeAttribute : TypeFilterAttribute
{
    public PermissionAuthorizeAttribute(string permission) : base(typeof(PermissionAuthorizeFilter))
    {
        Arguments = [permission];
    }
}

public sealed class PermissionAuthorizeFilter : IAsyncAuthorizationFilter
{
    private readonly string _permission;

    public PermissionAuthorizeFilter(string permission) => _permission = permission;

    public Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        if (!(context.HttpContext.User.Identity?.IsAuthenticated ?? false))
        {
            context.Result = new UnauthorizedObjectResult(new { success = false, error = new { code = "Unauthorized", message = "Authentication is required." } });
            return Task.CompletedTask;
        }

        if (!context.HttpContext.User.HasClaim(Claims.Permission, _permission))
        {
            context.Result = new ForbidResult();
        }

        return Task.CompletedTask;
    }
}