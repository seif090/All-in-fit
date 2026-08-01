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
    "DefaultConnection": "Server=localhost;Database=AllInFit;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true",
    "Redis": "localhost:6379",
    "RabbitMQ": "amqp://guest:guest@localhost:5672"
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
Write-Host "appsettings.json updated with connection strings and JWT config"

