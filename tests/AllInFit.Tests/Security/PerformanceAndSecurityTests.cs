using System.Diagnostics;
using System.Text.Json;
using AllInFit.Application.Validators;
using AllInFit.Presentation.Middleware;
using AllInFit.Application.Commands.Auth;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AllInFit.Tests.Security;

public sealed class PerformanceAndSecurityTests
{
    [Fact]
    public async Task GlobalExceptionMiddleware_ReturnsGenericPayloadWithoutStackTrace()
    {
        var middleware = new GlobalExceptionMiddleware(_ => throw new InvalidOperationException("Sensitive detail"), NullLogger<GlobalExceptionMiddleware>.Instance);
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        await middleware.InvokeAsync(context);

        context.Response.Body.Position = 0;
        using var reader = new StreamReader(context.Response.Body);
        var body = await reader.ReadToEndAsync();

        Assert.Contains("InternalServerError", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Sensitive detail", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void RegisterCommandValidator_RejectsWeakPasswords()
    {
        var validator = new RegisterCommandValidator();

        var result = validator.Validate(new RegisterCommand("user@example.com", "weak", "Jane", "Doe", "+15551234567"));

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(RegisterCommand.Password));
    }

    [Fact]
    public void ResultCreation_SmokePerformanceIsAcceptable()
    {
        var stopwatch = Stopwatch.StartNew();

        for (var index = 0; index < 100_000; index++)
        {
            _ = AllInFit.Shared.Result.Result.Success();
        }

        stopwatch.Stop();

        Assert.True(stopwatch.ElapsedMilliseconds < 1000, $"Result creation took {stopwatch.ElapsedMilliseconds}ms, which is slower than the expected smoke threshold.");
    }
}