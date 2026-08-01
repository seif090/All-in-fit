$ErrorActionPreference = "Stop"
$root = "c:\Users\seaif\Desktop\All in fit\src"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "WROTE $path"
}

# ===== Global Exception Handling Middleware =====
Write-File "$root\AllInFit.Presentation\Middleware\GlobalExceptionMiddleware.cs" @'
using System.Net;
using System.Text.Json;
using AllInFit.Shared.Result;

namespace AllInFit.Presentation.Middleware;

/// <summary>
/// Centralizes unhandled exception handling. Logs the exception and returns a
/// consistent JSON error envelope so clients never receive raw stack traces.
/// </summary>
public sealed class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception while processing {Method} {Path}",
                context.Request.Method, context.Request.Path);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
        context.Response.ContentType = "application/json";

        var error = new Error("InternalServerError",
            "An unexpected error occurred while processing your request.",
            ErrorType.Internal);

        var payload = new
        {
            success = false,
            error = new { code = error.Code, message = error.Message }
        };

        var json = JsonSerializer.Serialize(payload);
        await context.Response.WriteAsync(json);
    }
}

public static class GlobalExceptionMiddlewareExtensions
{
    public static IApplicationBuilder UseGlobalExceptionHandler(this IApplicationBuilder app)
        => app.UseMiddleware<GlobalExceptionMiddleware>();
}
'@

# ===== Request Logging Middleware (Serilog structured) =====
Write-File "$root\AllInFit.Presentation\Middleware\RequestLoggingMiddleware.cs" @'
using System.Diagnostics;

namespace AllInFit.Presentation.Middleware;

/// <summary>
/// Captures per-request timing and authentication status for structured logs.
/// Used to satisfy performance + audit logging requirements.
/// </summary>
public sealed class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var sw = Stopwatch.StartNew();
        var userId = context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        await _next(context);

        sw.Stop();
        _logger.LogInformation(
            "HTTP {Method} {Path} responded {StatusCode} in {ElapsedMs}ms (user={UserId})",
            context.Request.Method,
            context.Request.Path,
            context.Response.StatusCode,
            sw.ElapsedMilliseconds,
            userId);
    }
}

public static class RequestLoggingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder app)
        => app.UseMiddleware<RequestLoggingMiddleware>();
}
'@

# ===== Program.cs wiring for global exception handler + request logging =====
$programPath = "$root\AllInFit.Presentation\Program.cs"
$programContent = Get-Content $programPath -Raw -Encoding UTF8
$addUsings = @'
using AllInFit.Presentation.Middleware;
'@
if (-not $programContent.Contains("AllInFit.Presentation.Middleware")) {
    $programContent = $programContent.Replace("using Serilog;", "using Serilog;`n$addUsings")
}

$programContent = $programContent.Replace(
    "app.UseResponseCompression();",
    "app.UseGlobalExceptionHandler();`n`napp.UseResponseCompression();")

$programContent = $programContent.Replace(
    "app.UseSerilogRequestLogging();",
    "app.UseRequestLogging();`n`napp.UseSerilogRequestLogging();")

[System.IO.File]::WriteAllText($programPath, $programContent, [System.Text.Encoding]::UTF8)
Write-Host "PATCHED Program.cs (exception middleware + request logging)"

# ===== Postman collection =====
$postman = @{
    info = @{
        name = "All In Fit API"
        description = "Enterprise Health & Fitness SaaS platform - backend API collection."
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    variable = @(
        @{ key = "baseUrl"; value = "http://localhost:5199"; type = "string" }
        @{ key = "token"; value = ""; type = "string" }
    )
    auth = @{
        type = "bearer"
        bearer = @(@{ key = "token"; value = "{{token}}"; type = "string" })
    }
    item = @(
        @{
            name = "Auth"
            item = @(
                @{
                    name = "Register"
                    request = @{
                        method = "POST"
                        header = @(@{ key = "Content-Type"; value = "application/json" })
                        url = @{
                            raw = "{{baseUrl}}/api/v1/auth/register"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "auth", "register")
                        }
                        body = @{
                            mode = "raw"
                            raw = '{\n  "email": "user@example.com",\n  "password": "Str0ng!Pass",\n  "firstName": "John",\n  "lastName": "Doe"\n}'
                        }
                    }
                }
                @{
                    name = "Login"
                    request = @{
                        method = "POST"
                        header = @(@{ key = "Content-Type"; value = "application/json" })
                        url = @{
                            raw = "{{baseUrl}}/api/v1/auth/login"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "auth", "login")
                        }
                        body = @{
                            mode = "raw"
                            raw = '{\n  "email": "user@example.com",\n  "password": "Str0ng!Pass"\n}'
                        }
                    }
                }
                @{
                    name = "Refresh Token"
                    request = @{
                        method = "POST"
                        header = @(@{ key = "Content-Type"; value = "application/json" })
                        url = @{
                            raw = "{{baseUrl}}/api/v1/auth/refresh"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "auth", "refresh")
                        }
                        body = @{
                            mode = "raw"
                            raw = '{\n  "refreshToken": "PASTE_REFRESH_TOKEN_HERE"\n}'
                        }
                    }
                }
            )
        }
        @{
            name = "Users"
            item = @(
                @{
                    name = "Get Current User"
                    request = @{
                        method = "GET"
                        url = @{
                            raw = "{{baseUrl}}/api/v1/users/me"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "users", "me")
                        }
                    }
                }
                @{
                    name = "Get User By Id"
                    request = @{
                        method = "GET"
                        url = @{
                            raw = "{{baseUrl}}/api/v1/users/{{userId}}"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "users", "{{userId}}")
                        }
                    }
                }
            )
        }
        @{
            name = "Gyms"
            item = @(
                @{
                    name = "Get Gym"
                    request = @{
                        method = "GET"
                        url = @{
                            raw = "{{baseUrl}}/api/v1/gyms/{{gymId}}"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "gyms", "{{gymId}}")
                        }
                    }
                }
                @{
                    name = "Create Gym"
                    request = @{
                        method = "POST"
                        header = @(@{ key = "Content-Type"; value = "application/json" })
                        url = @{
                            raw = "{{baseUrl}}/api/v1/gyms"
                            host = @("{{baseUrl}}")
                            path = @("api", "v1", "gyms")
                        }
                        body = @{
                            mode = "raw"
                            raw = '{\n  "name": "Iron Temple Gym",\n  "legalName": "Iron Temple LLC",\n  "logoUrl": null,\n  "description": "A premium strength gym.",\n  "website": "https://irontemple.example"\n}'
                        }
                    }
                }
            )
        }
        @{
            name = "Health"
            item = @(
                @{
                    name = "Health Check"
                    request = @{
                        method = "GET"
                        url = @{
                            raw = "{{baseUrl}}/health"
                            host = @("{{baseUrl}}")
                            path = @("health")
                        }
                    }
                }
                @{
                    name = "Swagger JSON"
                    request = @{
                        method = "GET"
                        url = @{
                            raw = "{{baseUrl}}/swagger/v1/swagger.json"
                            host = @("{{baseUrl}}")
                            path = @("swagger", "v1", "swagger.json")
                        }
                    }
                }
            )
        }
    )
}

$postmanFolder = "c:\Users\seaif\Desktop\All in fit\docs"
if (-not (Test-Path $postmanFolder)) { New-Item -ItemType Directory -Path $postmanFolder -Force | Out-Null }
$postmanPath = "$postmanFolder\AllInFit.postman_collection.json"
[System.IO.File]::WriteAllText($postmanPath, ($postman | ConvertTo-Json -Depth 20), [System.Text.Encoding]::UTF8)
Write-Host "WROTE $postmanPath"

Write-Host "generate-middleware-postman.ps1 complete."

