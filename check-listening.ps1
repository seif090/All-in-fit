Write-Host "=== Listening ports (dotnet processes) ==="
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.OwningProcess -in (Get-Process -Name dotnet -ErrorAction SilentlyContinue).Id } |
    Select-Object LocalAddress, LocalPort, OwningProcess |
    Sort-Object LocalPort |
    Format-Table -AutoSize

Write-Host "=== dotnet processes ==="
Get-Process -Name dotnet -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, StartTime, @{N='Path';E={$_.Path}} |
    Format-Table -AutoSize

Write-Host "=== Try common health URLs ==="
foreach ($port in @(5199, 5000, 5001, 7000, 7001, 5050, 5040)) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:$port/health" -UseBasicParsing -TimeoutSec 3
        Write-Host "[$port] -> $($r.StatusCode) $($r.Content)"
    } catch {
        # skip
    }
}
Write-Host "=== Done ==="
