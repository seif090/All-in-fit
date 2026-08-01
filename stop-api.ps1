$connections = Get-NetTCPConnection -State Listen -LocalPort 5199 -ErrorAction SilentlyContinue
if ($connections) {
    foreach ($conn in $connections) {
        $procId = $conn.OwningProcess
        Write-Host "Stopping process $procId listening on 5199..."
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "No process listening on 5199."
}

# Also stop any dotnet processes that might be our API
Get-Process -Name dotnet -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID } | ForEach-Object {
    # Only stop dotnet processes with a MainModule path pointing at our presentation project
    try {
        $path = $_.Path
        if ($path -like '*AllInFit*') {
            Write-Host "Stopping dotnet process $($_.Id) ($path)"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # skip
    }
}

Start-Sleep -Seconds 2
Write-Host "Port 5199 free check:"
Get-NetTCPConnection -State Listen -LocalPort 5199 -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess | Format-Table -AutoSize
Write-Host "Done."
