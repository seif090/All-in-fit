Write-Host "=== AspNetRoles ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT Id, Name FROM AspNetRoles ORDER BY Name" -W 2>&1

Write-Host ""
Write-Host "=== Permissions count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS PermissionCount FROM Permissions" -W 2>&1

Write-Host ""
Write-Host "=== AspNetUsers ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT TOP 5 Id, Email, UserName FROM AspNetUsers" -W 2>&1

Write-Host ""
Write-Host "=== RoleClaims count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS RoleClaimCount FROM AspNetRoleClaims" -W 2>&1

Write-Host ""
Write-Host "=== UserRoles count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS UserRoleCount FROM AspNetUserRoles" -W 2>&1

