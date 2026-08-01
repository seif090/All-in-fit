$ErrorActionPreference = "Stop"
try {
    $r = Invoke-WebRequest -Uri "http://localhost:5199/health" -UseBasicParsing -TimeoutSec 15
    Write-Host ("STATUS: " + $r.StatusCode)
    Write-Host ("BODY: " + $r.Content)
} catch {
    $resp = $_.Exception.Response
    if ($resp) {
        Write-Host ("STATUS: " + [int]$resp.StatusCode)
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $body = $reader.ReadToEnd()
        Write-Host ("BODY: " + $body)
    } else {
        Write-Host ("NO RESPONSE: " + $_.Exception.Message)
    }
}

