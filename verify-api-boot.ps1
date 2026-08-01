$ErrorActionPreference = "Continue"

$logOut = "c:\Users\seaif\Desktop\All in fit\api-stdout.log"
$logErr = "c:\Users\seaif\Desktop\All in fit\api-stderr.log"

$p = Start-Process -FilePath "dotnet" `
    -ArgumentList "run --no-build --project src/AllInFit.Presentation/AllInFit.Presentation.csproj --urls http://localhost:5199" `
    -WorkingDirectory "c:\Users\seaif\Desktop\All in fit" `
    -PassThru `
    -RedirectStandardOutput $logOut `
    -RedirectStandardError $logErr

Write-Host "API started (PID $($p.Id)). Waiting for boot..."
Start-Sleep -Seconds 18

try {
    $r = Invoke-WebRequest -Uri "http://localhost:5199/health" -UseBasicParsing -TimeoutSec 15
    Write-Host "HEALTH STATUS: $($r.StatusCode)"
    Write-Host $r.Content
} catch {
    Write-Host "HEALTH ERROR: $($_.Exception.Message)"
}

Write-Host "----- STDERR (last 30 lines) -----"
if (Test-Path $logErr) { Get-Content $logErr -Tail 30 }

Write-Host "----- STDOUT (last 15 lines) -----"
if (Test-Path $logOut) { Get-Content $logOut -Tail 15 }

Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
# Kill any child process still holding the port (dotnet run spawns child)
Get-CimInstance Win32_Process -Filter "Name='dotnet.exe'" | Where-Object { $_.CommandLine -like "*AllInFit.Presentation*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host "API process stopped."

