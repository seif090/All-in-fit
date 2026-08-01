using AllInFit.Application;
using AllInFit.Infrastructure;
using AllInFit.Infrastructure.Jobs;
using AllInFit.Infrastructure.Logging;
using AllInFit.Infrastructure.Realtime;
using AllInFit.Persistence;
using AllInFit.Persistence.Data;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((context, services, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext();
});
LoggerSetup.ConfigureLogger();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Layer registrations
builder.Services.AddApplicationLayer();
builder.Services.AddPersistenceLayer(builder.Configuration);
builder.Services.AddInfrastructureLayer(builder.Configuration);

// Health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>(name: "database", tags: ["database", "sql"]);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Initialize database (apply migrations + seed data)
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    await DbInitializer.InitializeAsync(app.Services, logger);
}

app.UseSerilogRequestLogging();

app.UseHttpsRedirection();

app.UseRateLimiter();

app.UseAuthorization();

app.MapControllers();

// SignalR hubs (live notifications + chat)
app.MapHub<NotificationsHub>(NotificationsHub.HubPath);
app.MapHub<ChatHub>(ChatHub.HubPath);

// Hangfire dashboard + recurring background jobs (config-gated)
app.UseHangfireDashboardJobs(builder.Configuration);

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";

        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            totalChecks = report.Entries.Count,
            duration = report.TotalDuration,
            entries = report.Entries.ToDictionary(
                e => e.Key,
                e => new
                {
                    status = e.Value.Status.ToString(),
                    description = e.Value.Description,
                    exception = e.Value.Exception?.Message,
                    duration = e.Value.Duration
                })
        });

        await context.Response.WriteAsync(result);
    }
});

app.Run();

public partial class Program;