Write-Host "=== Existence of key tables ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT name FROM sys.tables WHERE name IN ('Roles','Users','Permissions','RolePermissions','AspNetRoles','AspNetUsers','Products','Appointments','Gyms','Wallets') ORDER BY name" -W 2>&1

Write-Host ""
Write-Host "=== Roles table rows ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS RoleCount FROM Roles" -W 2>&1

Write-Host ""
Write-Host "=== AspNetRoles table rows ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS AspNetRoleCount FROM AspNetRoles" -W 2>&1

Write-Host ""
Write-Host "=== Permissions rows ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS PermissionCount FROM Permissions" -W 2>&1

Write-Host ""
Write-Host "=== RolePermissions rows ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS RolePermissionCount FROM RolePermissions" -W 2>&1

Write-Host ""
Write-Host "=== Users rows ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS UserCount FROM Users" -W 2>&1

Write-Host ""
Write-Host "=== Migrations applied ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT MigrationId, ProductVersion FROM __EFMigrationsHistory" -W 2>&1

Write-Host ""
Write-Host "=== Total table count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS Total FROM sys.tables" -W 2>&1

