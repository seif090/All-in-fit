# =====================================================================
# Fix 1: InMemoryEventBus.cs — add using Microsoft.Extensions.DependencyInjection
# =====================================================================
$inMemoryPath = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure\Messaging\InMemoryEventBus.cs"
$c1 = [System.IO.File]::ReadAllText($inMemoryPath)
if (-not $c1.Contains("using Microsoft.Extensions.DependencyInjection;")) {
    $c1 = $c1.Replace("using Microsoft.Extensions.Logging;", "using Microsoft.Extensions.DependencyInjection;`r`nusing Microsoft.Extensions.Logging;")
    [System.IO.File]::WriteAllText($inMemoryPath, $c1, [System.Text.Encoding]::UTF8)
    Write-Host "InMemoryEventBus.cs: added DI using."
} else {
    Write-Host "InMemoryEventBus.cs: DI using already present."
}

# =====================================================================
# Fix 2: DependencyInjection.cs — add usings for Realtime / RateLimiting / Jobs
# =====================================================================
$diPath = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure\DependencyInjection.cs"
$c2 = [System.IO.File]::ReadAllText($diPath)

$usingAdditions = @(
    'using AllInFit.Infrastructure.Jobs;',
    'using AllInFit.Infrastructure.RateLimiting;',
    'using AllInFit.Infrastructure.Realtime;'
)

$added = 0
foreach ($u in $usingAdditions) {
    if (-not $c2.Contains($u)) {
        $c2 = $c2.Replace("using AllInFit.Infrastructure.Payments;", "$u`r`nusing AllInFit.Infrastructure.Payments;")
        $added++
    }
}

# Sanity: ensure using block remains at top
if ($added -gt 0) {
    [System.IO.File]::WriteAllText($diPath, $c2, [System.Text.Encoding]::UTF8)
    Write-Host "DependencyInjection.cs: added $added usings."
} else {
    Write-Host "DependencyInjection.cs: usings already present."
}

