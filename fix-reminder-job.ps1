$path = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Infrastructure\Jobs\AppointmentReminderJob.cs"
$c = [System.IO.File]::ReadAllText($path)

# BaseEntity.Id has a protected setter — remove the explicit assignment.
$c = $c.Replace(
    "            var notification = new Notification`r`n            {`r`n                Id = Guid.NewGuid(),`r`n                UserId = appointment.UserId,",
    "            var notification = new Notification`r`n            {`r`n                UserId = appointment.UserId,")

if ($c -match 'Id = Guid.NewGuid\(\),') {
    # Try single-line variant too
    $c = $c.Replace(
        "            var notification = new Notification`r`n            {`r`n                Id = Guid.NewGuid(),",
        "            var notification = new Notification`r`n            {")
}

[System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
Write-Host "AppointmentReminderJob.cs updated (removed explicit Id assignment)."

