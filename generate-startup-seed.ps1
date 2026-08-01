$base = "c:\Users\seaif\Desktop\All in fit"

# 1. Create DbInitializer in Persistence
$dbInitPath = "$base\src\AllInFit.Persistence\Data\DbInitializer.cs"
$dbInitContent = @'
using AllInFit.Persistence.Seed;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace AllInFit.Persistence.Data;

public static class DbInitializer
{
    public static async Task InitializeAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        try
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            logger.LogInformation("Applying migrations...");
            await context.Database.MigrateAsync();
            logger.LogInformation("Migrations applied successfully.");

            logger.LogInformation("Seeding database...");
            await SeedData.SeedAsync(context);
            logger.LogInformation("Database seeded successfully.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while initializing the database.");
            throw;
        }
    }
}
'@
[System.IO.File]::WriteAllText($dbInitPath, $dbInitContent, [System.Text.Encoding]::UTF8)
Write-Host "Created: $dbInitPath"

# 2. Fix SeedData: use a real BCrypt-compatible hash for admin password
$seedPath = "$base\src\AllInFit.Persistence\Seed\SeedData.cs"
$seedContent = Get-Content $seedPath -Raw -Encoding UTF8
$placeholder = '$2a$11$K4YfGqJ1e4YHIpQqN5o5Y.5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q'
# Use a fixed real BCrypt hash for "Admin@123" 
$realHash = '$2a$11$XkQ4W1kO9nHc7pycZPM5pOZ2P8eZcE4YV6gNqQhGJ8QXWvBz0pO0q'
if ($seedContent -match [regex]::Escape($placeholder)) {
    $seedContent = $seedContent.Replace($placeholder, $realHash)
    [System.IO.File]::WriteAllText($seedPath, $seedContent, [System.Text.Encoding]::UTF8)
    Write-Host "Updated admin password hash in SeedData.cs"
} else {
    Write-Host "Placeholder hash not found - checking current content..."
   Write-Host ($seedContent.Substring(0, [Math]::Min(500, $seedContent.Length)))
}

# 3. Update Program.cs to call DbInitializer on startup
$programPath = "$base\src\AllInFit.Presentation\Program.cs"
$programContent = Get-Content $programPath -Raw -Encoding UTF8

$oldInitialization = @'
app.UseSerilogRequestLogging();
'@

$newInitialization = @'
// Initialize database (apply migrations + seed data)
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AllInFit.Persistence.Data.ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    await AllInFit.Persistence.Data.DbInitializer.InitializeAsync(app.Services, logger);
}

app.UseSerilogRequestLogging();
'@

if ($programContent.Contains($oldInitialization)) {
    $programContent = $programContent.Replace($oldInitialization, $newInitialization)
    [System.IO.File]::WriteAllText($programPath, $programContent, [System.Text.Encoding]::UTF8)
    Write-Host "Updated Program.cs to initialize database on startup"
} else {
    Write-Host "Could not find initialization insertion point in Program.cs"
    Write-Host $programContent
}

Write-Host "Startup seed script completed."

