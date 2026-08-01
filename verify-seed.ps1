Write-Host "=== Roles ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT Name FROM Roles ORDER BY Name" -W 2>&1

Write-Host ""
Write-Host "=== Permissions count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS PermissionCount FROM Permissions" -W 2>&1

Write-Host ""
Write-Host "=== Users ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT TOP 5 Id, Email, FirstName, LastName, AccountType FROM Users" -W 2>&1

Write-Host ""
Write-Host "=== RolePermissions count ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS RolePermissionCount FROM RolePermissions" -W 2>&1

Write-Host ""
Write-Host "=== Role - permission join sample (SuperAdmin) ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT TOP 5 r.Name, p.Name FROM RolePermissions rp JOIN Roles r ON rp.RoleId = r.Id JOIN Permissions p ON rp.PermissionId = p.Id WHERE r.Name = 'SuperAdmin'" -W 2>&1

Write-Host ""
Write-Host "=== Tables (count) ==="
sqlcmd -S localhost -E -d AllInFit -Q "SELECT COUNT(*) AS TableCount FROM sys.tables" -W 2>&1

