$ErrorActionPreference = "Stop"
$path = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Presentation\appsettings.json"
$content = @'
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.AspNetCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" },
      {
        "Name": "File",
        "Args": {
          "path": "logs/allinfit-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 30
        }
      }
    ],
    "Enrich": ["FromLogContext", "WithThreadId", "WithMachineName", "WithEnvironmentName"],
    "Properties": {
      "Application": "AllInFit"
    }
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=AllInFit;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
  },
  "Jwt": {
    "Issuer": "AllInFit",
    "Audience": "AllInFit",
    "SecretKey": "AllInFit-SuperSecret-Key-Minimum-32-Characters-Long!",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7
  },
  "Cache": {
    "Enabled": false
  },
  "Hangfire": {
    "Enabled": false,
    "DashboardPath": "/hangfire",
    "WorkerCount": 4,
    "Queues": ["default", "notifications", "payments", "reports"]
  },
  "RateLimiting": {
    "Enabled": true,
    "PermitLimit": 100,
    "WindowSeconds": 60,
    "QueueLimit": 10
  }
}
'@
[System.IO.File]::WriteAllText($path, $content.TrimStart(), [System.Text.Encoding]::UTF8)
Write-Host "appsettings.json updated with Serilog console+file sinks"

