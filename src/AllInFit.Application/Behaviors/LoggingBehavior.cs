using MediatR;
using Microsoft.Extensions.Logging;

namespace AllInFit.Application.Behaviors;

public sealed class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;
    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger) => _logger = logger;

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling {RequestType} at {Time}", typeof(TRequest).Name, DateTime.UtcNow);
        var response = await next();
        _logger.LogInformation("Handled {RequestType} at {Time}", typeof(TRequest).Name, DateTime.UtcNow);
        return response;
    }
}