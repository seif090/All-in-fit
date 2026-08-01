$path = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Presentation\appsettings.json"

$content = @'
{
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
  "Cache": {
    "Enabled": false,
    "RedisConnectionString": "",
    "DefaultExpirationMinutes": 30
  },
  "Jwt": {
    "Issuer": "AllInFit",
    "Audience": "AllInFit",
    "SecretKey": "AllInFit-SuperSecret-Key-Minimum-32-Characters-Long!",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7
  }
}
'@

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "appsettings.json updated: Cache.Enabled=false (memory cache fallback), no Redis/RabbitMQ defaults"
