$p = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure\Messaging\InMemoryEventBus.cs"
$c = [System.IO.File]::ReadAllText($p)
if ($c -notmatch 'using Microsoft.Extensions.DependencyInjection;') {
    $c = $c.Replace('using Microsoft.Extensions.Logging;', "using Microsoft.Extensions.DependencyInjection;`r`nusing Microsoft.Extensions.Logging;")
    [System.IO.File]::WriteAllText($p, $c, [System.Text.Encoding]::UTF8)
    Write-Host "Added DI using to InMemoryEventBus.cs"
} else {
    Write-Host "DI using already present."
}

