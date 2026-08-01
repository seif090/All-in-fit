$query = "SELECT name FROM sys.databases WHERE name='AllInFit'"
$result = sqlcmd -S localhost -E -Q $query -W 2>&1
Write-Host $result

$query2 = "SELECT COUNT(*) AS TableCount FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo')"
$result2 = sqlcmd -S localhost -E -d AllInFit -Q $query2 -W 2>&1
Write-Host "Table count:"
Write-Host $result2

