$ErrorActionPreference = "SilentlyContinue"

$url = "http://localhost:5199/health"
$attempts = 12
$success = $false

for ($i = 1; $i -le $attempts; $i++) {
    Write-Host ("Attempt $i / $attempts ...")
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15
        Write-Host ("Health Status: " + $r.StatusCode + " " + $r.Content)
        $success = $true
        break
    } catch {
        $msg = $_.Exception.Message
        Write-Host ("  health fail: " + $msg)
        Start-Sleep -Seconds 5
    }
}

if (-not $success) {
    Write-Host "--- Checking listeners on 5199 ---"
    Get-NetTCPConnection -State Listen -LocalPort 5199 -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess | Format-Table -AutoSize
}

