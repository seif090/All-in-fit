$path = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure\Jobs\HangfireRegistration.cs"
$c = [System.IO.File]::ReadAllText($path)

$need = @(
    'using Microsoft.AspNetCore.Builder;',
    'using Microsoft.AspNetCore.Http;',
    'using Hangfire.Dashboard;'
)

$added = 0
foreach ($u in $need) {
    if (-not $c.Contains($u)) {
        # Insert after the last existing using line (right before namespace).
        $marker = "using Microsoft.Extensions.Options;"
        if ($c.Contains($marker)) {
            $c = $c.Replace($marker, "$marker`r`n$u")
            $added++
        }
    }
}

[System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
Write-Host "HangfireRegistration.cs usings fixed ($added added)."

