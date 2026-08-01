using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Caching.Memory;

namespace AllInFit.Presentation.Filters;

public sealed class CachedResponseAttribute : TypeFilterAttribute
{
    public CachedResponseAttribute(int seconds) : base(typeof(ResponseCachingFilter))
    {
        Arguments = [seconds];
    }
}

public sealed class ResponseCachingFilter : IAsyncActionFilter
{
    private readonly IMemoryCache _cache;
    private readonly int _seconds;

    public ResponseCachingFilter(IMemoryCache cache, int seconds)
    {
        _cache = cache;
        _seconds = seconds;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (!HttpMethods.IsGet(context.HttpContext.Request.Method))
        {
            await next();
            return;
        }

        var userId = context.HttpContext.User.FindFirst("sub")?.Value ?? context.HttpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous";
        var cacheKey = $"response:{userId}:{context.HttpContext.Request.Path}:{context.HttpContext.Request.QueryString}";

        if (_cache.TryGetValue(cacheKey, out CachedActionResult? cached) && cached is not null)
        {
            context.Result = new ObjectResult(cached.Value) { StatusCode = cached.StatusCode };
            return;
        }

        var executed = await next();

        if (executed.Result is ObjectResult objectResult && objectResult.StatusCode is null or >= 200 and <= 299)
        {
            _cache.Set(cacheKey, new CachedActionResult(objectResult.Value, objectResult.StatusCode), TimeSpan.FromSeconds(_seconds));
        }
    }
}

public sealed record CachedActionResult(object? Value, int? StatusCode);